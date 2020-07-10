defmodule Mpnetwork.Search do
  @moduledoc """
  It made sense to move all the search functionality into its own module.
  """
  import Ecto.Query, warn: false

  alias Mpnetwork.Realtor.Listing
  alias Mpnetwork.{Repo, Permissions, Realtor, EnumMaps}

  @listing_status_types EnumMaps.listing_status_types_int_bin()
  @active_listing_status_types ~w[CS NEW FS EXT PC]
  @inactive_listing_status_types (@listing_status_types -- @active_listing_status_types)

  defp default_search_scope(current_user) do
    # regular realtor
    if Permissions.office_admin_or_site_admin?(current_user) do
      # site admin
      if Permissions.office_admin?(current_user) do
        current_office = Realtor.get_office!(current_user.office_id)

        from(
          l in Listing,
          where: l.draft == false or l.broker_id == ^current_office.id,
          order_by: [desc: l.updated_at],
          preload: [:broker, :user]
        )
      else
        from(l in Listing, order_by: [desc: l.updated_at], preload: [:broker, :user])
      end
    else
      from(
        l in Listing,
        where: l.draft == false or l.user_id == ^current_user.id,
        order_by: [desc: l.updated_at],
        preload: [:broker, :user]
      )
    end
  end

  defp nil_search_scope do
    from(
      l in Listing,
      where: l.id == -1
    )
  end

  defp scope_nothing_if_errors(state = {_query, _scope, []}), do: state
  defp scope_nothing_if_errors({query, _scope, errors}), do: {query, nil_search_scope(), errors}

  @doc """
  Queries listings.
  """
  def query_listings("", max, current_user) do
    blank_scope =
      default_search_scope(current_user) |> where([l], l.listing_status_type in @active_listing_status_types)

    limited_scope = blank_scope |> limit([l], ^max)
    total_count = Repo.aggregate(blank_scope, :count, :id)
    {total_count, Repo.all(limited_scope), []}
  end

  def query_listings(query, max, current_user) do
    # should return {"unconsumed_query", new_scope, any_errors} ... down the line
    blank_scope = default_search_scope(current_user)

    {_consumed_query, final_scope, errors} =
      {query, blank_scope, []}
      |> try_determine_default_scope()
      |> try_my_office(current_user)
      |> try_mine(current_user)
      |> try_pricerange()
      |> try_daterange()
      |> try_active_inactive()
      |> try_listing_status_type()
      |> search_all_fields_using_postgres_fulltext_search()
      |> try_id()
      |> scope_nothing_if_errors()

    limited_final_scope = final_scope |> limit([l], ^max)

    # IO.inspect(Ecto.Adapters.SQL.to_sql(:all, Repo, final_scope), limit: :infinity, printable_limit: :infinity)
    total_count =
      try do
        Repo.aggregate(final_scope, :count, :id)
      rescue
        Postgrex.Error -> 0
      end

    {listings, errors} =
      try do
        {Repo.all(limited_final_scope), errors}
      rescue
        Postgrex.Error -> {[], ["Something was wrong with the search query: #{query}" | errors]}
      end

    {total_count, listings, errors}
  end

  defp try_id({query, scope, errors}) do
    if Regex.match?(~r/^[0-9]+$/, query) do
      id = _try_integer(query)
      {query, scope |> or_where([l], l.id == ^id), errors}
    else
      {query, scope, errors}
    end
  end

  defp _try_integer(num) when is_integer(num), do: num

  defp _try_integer(maybe_num) when is_binary(maybe_num) do
    _try_int_result(Integer.parse(maybe_num))
  end

  defp _try_int_result({num, ""}) do
    num
  end

  defp _try_int_result(_) do
    nil
  end

  # just matching on Long Island zipcodes for now
  # one day these may collide with searching by ID#
  # hashtag ProblemsIdLikeToHave
  # Abandoned this because it broke tests as soon as id's started with 11nnn >..<
  # @zipcode_regex ~r/\b11[0-9]{3}\b/
  # defp _try_zipcode({query, _scope, _errors}) do
  #   Regex.match?(@zipcode_regex, query)
  # end

  defp convert_binary_date_parts_to_naivedatetime_struct(year, month, day)
       when is_binary(year) and is_binary(month) and is_binary(day) do
    date =
      case Date.new(_try_integer(year), _try_integer(month), _try_integer(day)) do
        {:ok, date} -> date
        {:error, _} -> nil
      end

    case date do
      nil ->
        nil

      date ->
        {:ok, date} = NaiveDateTime.new(date, ~T[00:00:00])
        date
    end
  end

  @my_office_regex ~r/ ?\bmy office\b ?/i
  defp try_my_office({query, scope, errors}, current_user) do
    if Regex.match?(@my_office_regex, query) do
      current_office = Realtor.get_office!(current_user.office_id)

      {Regex.replace(@my_office_regex, query, ""),
       scope |> where([l], l.broker_id == ^current_office.id), errors}
    else
      {query, scope, errors}
    end
  end

  @mine_regex ~r/ ?\b(?:my|mine)\b ?/i
  defp try_mine({query, scope, errors}, current_user) do
    if Regex.match?(@mine_regex, query) do
      {Regex.replace(@mine_regex, query, ""), scope |> where([l], l.user_id == ^current_user.id),
       errors}
    else
      {query, scope, errors}
    end
  end

  @pricerange_regex ~r/\$?([0-9,]{3,}) ?\- ?\$?([0-9,]{3,})/
  defp try_pricerange({query, scope, errors}) do
    pr =
      case Regex.run(@pricerange_regex, query) do
        [_, start, finish] -> {_filter_nonnumeric(start), _filter_nonnumeric(finish)}
        _ -> nil
      end

    if pr do
      {start, finish} = pr

      {Regex.replace(@pricerange_regex, query, ""),
       scope
       |> where(
         [l],
         (l.price_usd >= ^start and l.price_usd <= ^finish) or
           (l.rental_price_usd >= ^start and l.rental_price_usd <= ^finish)
       ), errors}
    else
      {query, scope, errors}
    end
  end

  # search on "for sale" date (listing date)
  @daterange_fs_regex ~r/(?:fs|for sale): ?([01]?[0-9])\/([0123]?[0-9])\/([0-9]{4}) ?\- ?([01]?[0-9])\/([0123]?[0-9])\/([0-9]{4})/i
  # search on "under contract" date
  @daterange_uc_regex ~r/(?:uc|under contract): ?([01]?[0-9])\/([0123]?[0-9])\/([0-9]{4}) ?\- ?([01]?[0-9])\/([0123]?[0-9])\/([0-9]{4})/i
  # search on "closed" date
  @daterange_cl_regex ~r/(?:cl|closed): ?([01]?[0-9])\/([0123]?[0-9])\/([0-9]{4}) ?\- ?([01]?[0-9])\/([0123]?[0-9])\/([0-9]{4})/i
  # search on "expired" date
  @daterange_exp_regex ~r/(?:exp|expired): ?([01]?[0-9])\/([0123]?[0-9])\/([0-9]{4}) ?\- ?([01]?[0-9])\/([0123]?[0-9])\/([0-9]{4})/i

  defp _process_daterangesearch(
         {query, scope, errors},
         :FS,
         regex,
         {start_yr, start_mon, start_day},
         {finish_yr, finish_mon, finish_day}
       ) do
    valid_startday =
      convert_binary_date_parts_to_naivedatetime_struct(start_yr, start_mon, start_day)

    valid_finishday =
      convert_binary_date_parts_to_naivedatetime_struct(finish_yr, finish_mon, finish_day)

    cond do
      valid_startday && valid_finishday ->
        {Regex.replace(regex, query, ""),
         scope |> where([l], l.live_at >= ^valid_startday and l.live_at <= ^valid_finishday),
         errors}

      !valid_startday && valid_finishday ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Invalid start day in Listing Date search range: #{start_mon}/#{start_day}/#{start_yr}"
           | errors
         ]}

      valid_startday && !valid_finishday ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Invalid end day in Listing Date search range: #{finish_mon}/#{finish_day}/#{finish_yr}"
           | errors
         ]}

      true ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Dates are both invalid in Listing Date search range: #{start_mon}/#{start_day}/#{
             start_yr
           }-#{finish_mon}/#{finish_day}/#{finish_yr}"
           | errors
         ]}
    end
  end

  defp _process_daterangesearch(
         {query, scope, errors},
         :UC,
         regex,
         {start_yr, start_mon, start_day},
         {finish_yr, finish_mon, finish_day}
       ) do
    valid_startday =
      convert_binary_date_parts_to_naivedatetime_struct(start_yr, start_mon, start_day)

    valid_finishday =
      convert_binary_date_parts_to_naivedatetime_struct(finish_yr, finish_mon, finish_day)

    cond do
      valid_startday && valid_finishday ->
        {Regex.replace(regex, query, ""),
         scope |> where([l], l.uc_on >= ^valid_startday and l.uc_on <= ^valid_finishday), errors}

      !valid_startday && valid_finishday ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Invalid start day in Under Contract date search range: #{start_mon}/#{start_day}/#{
             start_yr
           }"
           | errors
         ]}

      valid_startday && !valid_finishday ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Invalid end day in Under Contract date search range: #{finish_mon}/#{finish_day}/#{
             finish_yr
           }"
           | errors
         ]}

      true ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Dates are both invalid in Under Contract date search range: #{start_mon}/#{start_day}/#{
             start_yr
           }-#{finish_mon}/#{finish_day}/#{finish_yr}"
           | errors
         ]}
    end
  end

  defp _process_daterangesearch(
         {query, scope, errors},
         :CL,
         regex,
         {start_yr, start_mon, start_day},
         {finish_yr, finish_mon, finish_day}
       ) do
    valid_startday =
      convert_binary_date_parts_to_naivedatetime_struct(start_yr, start_mon, start_day)

    valid_finishday =
      convert_binary_date_parts_to_naivedatetime_struct(finish_yr, finish_mon, finish_day)

    cond do
      valid_startday && valid_finishday ->
        {Regex.replace(regex, query, ""),
         scope |> where([l], l.closed_on >= ^valid_startday and l.closed_on <= ^valid_finishday),
         errors}

      !valid_startday && valid_finishday ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Invalid start day in Closing Date search range: #{start_mon}/#{start_day}/#{start_yr}"
           | errors
         ]}

      valid_startday && !valid_finishday ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Invalid end day in Closing Date search range: #{finish_mon}/#{finish_day}/#{finish_yr}"
           | errors
         ]}

      true ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Dates are both invalid in Closing Date search range: #{start_mon}/#{start_day}/#{
             start_yr
           }-#{finish_mon}/#{finish_day}/#{finish_yr}"
           | errors
         ]}
    end
  end

  defp _process_daterangesearch(
         {query, scope, errors},
         :EXP,
         regex,
         {start_yr, start_mon, start_day},
         {finish_yr, finish_mon, finish_day}
       ) do
    valid_startday =
      convert_binary_date_parts_to_naivedatetime_struct(start_yr, start_mon, start_day)

    valid_finishday =
      convert_binary_date_parts_to_naivedatetime_struct(finish_yr, finish_mon, finish_day)

    cond do
      valid_startday && valid_finishday ->
        {Regex.replace(regex, query, ""),
         scope
         |> where([l], l.expires_on >= ^valid_startday and l.expires_on <= ^valid_finishday),
         errors}

      !valid_startday && valid_finishday ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Invalid start day in Expired Date search range: #{start_mon}/#{start_day}/#{start_yr}"
           | errors
         ]}

      valid_startday && !valid_finishday ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Invalid end day in Expired Date search range: #{finish_mon}/#{finish_day}/#{finish_yr}"
           | errors
         ]}

      true ->
        {Regex.replace(regex, query, ""), scope,
         [
           "Dates are both invalid in Expired Date search range: #{start_mon}/#{start_day}/#{
             start_yr
           }-#{finish_mon}/#{finish_day}/#{finish_yr}"
           | errors
         ]}
    end
  end

  defp try_daterange({query, scope, errors}) do
    {query, scope, errors} =
      case Regex.run(@daterange_fs_regex, query) do
        [_, start_mon, start_day, start_yr, finish_mon, finish_day, finish_yr] ->
          _process_daterangesearch(
            {query, scope, errors},
            :FS,
            @daterange_fs_regex,
            {start_yr, start_mon, start_day},
            {finish_yr, finish_mon, finish_day}
          )

        _ ->
          {query, scope, errors}
      end

    {query, scope, errors} =
      case Regex.run(@daterange_uc_regex, query) do
        [_, start_mon, start_day, start_yr, finish_mon, finish_day, finish_yr] ->
          _process_daterangesearch(
            {query, scope, errors},
            :UC,
            @daterange_uc_regex,
            {start_yr, start_mon, start_day},
            {finish_yr, finish_mon, finish_day}
          )

        _ ->
          {query, scope, errors}
      end

    {query, scope, errors} =
      case Regex.run(@daterange_cl_regex, query) do
        [_, start_mon, start_day, start_yr, finish_mon, finish_day, finish_yr] ->
          _process_daterangesearch(
            {query, scope, errors},
            :CL,
            @daterange_cl_regex,
            {start_yr, start_mon, start_day},
            {finish_yr, finish_mon, finish_day}
          )

        _ ->
          {query, scope, errors}
      end

    {query, scope, errors} =
      case Regex.run(@daterange_exp_regex, query) do
        [_, start_mon, start_day, start_yr, finish_mon, finish_day, finish_yr] ->
          _process_daterangesearch(
            {query, scope, errors},
            :EXP,
            @daterange_exp_regex,
            {start_yr, start_mon, start_day},
            {finish_yr, finish_mon, finish_day}
          )

        _ ->
          {query, scope, errors}
      end

    {query, scope, errors}
  end

  # If you search on a capitalized listing status, replace with specifically-indexed listing status word "lst/<listing_status>"
  @listing_status_type_regex ~r/\b(#{Enum.join(@listing_status_types, "|")})\b/
  defp try_listing_status_type({query, scope, errors}) do
    query = Regex.replace(@listing_status_type_regex, query, "lst/\\1")
    {query, scope, errors}
  end

  # Default to active listing statuses unless any of these searches are performed
  @active_regex ~r/\b(?:active|available)\b/i
  @inactive_regex ~r/\b(?:inactive|unavailable)\b/i
  @all_regex ~r/\ball\b/i
  @expired_regex ~r/\bexpired\b/i
  defp try_determine_default_scope({query, scope, errors}) do
    if Regex.match?(@all_regex, query) or
         Regex.match?(@active_regex, query) or
         Regex.match?(@inactive_regex, query) or
         Regex.match?(@listing_status_type_regex, query) or
         Regex.match?(@expired_regex, query) or
         Regex.match?(@daterange_fs_regex, query) or
         Regex.match?(@daterange_uc_regex, query) or
         Regex.match?(@daterange_cl_regex, query) or
         Regex.match?(@daterange_exp_regex, query) do
      # just pass it through
      {Regex.replace(@all_regex, query, ""), scope, errors}
    else
      # default to active scope
      {Regex.replace(@active_regex, query, ""),
       scope |> where([l], l.listing_status_type in @active_listing_status_types), errors}
    end
  end

  defp try_active_inactive({query, scope, errors}) do
    query = Regex.replace(@active_regex, query, "(#{Enum.join(@active_listing_status_types, "|")})")
    query = Regex.replace(@inactive_regex, query, "(#{Enum.join(@inactive_listing_status_types, "|")})")
    {query, scope, errors}
  end

  defp _filter_nonnumeric(num) when is_binary(num) do
    {num, _} = Integer.parse(Regex.replace(~r/[^0-9]+/, num, ""))
    num
  end

  # list of ordinals:
  # room, bedroom, bathroom, fireplace, skylight, garage, family, story
  # Upper range limit of these being processed correctly is 29
  defp normalization_transformations() do
    [
      # normalizes "no smoking" to "nosmoking" (so as not to be caught by the next match; see the following one)
      {~r/"?\bno\ssmoking\b"?/i, "nosmoking"},
      # normalizes "smoking" and "smoking ok" to "(smoking<->ok)|!(no<->smoking)"
      {~r/"?\bsmoking(?:\sok)?\b"?/i, "((smoking<->ok)&!(no<->smoking))"},
      # normalizes "nosmoking" to "!(smoking<->ok)|(no<->smoking)"
      {~r/\bnosmoking\b/i, "((no<->smoking)|!(smoking<->ok))"},
      # normalizes "no pets" to "nopets" (so as not to be caught by the next match; see the following one)
      {~r/"?\bno\spets\b"?/i, "nopets"},
      # normalizes "pets" and "pets ok" to "(pets<->ok)|!(no<->pets)"
      {~r/"?\bpets(?:\sok)?\b"?/i, "((pets<->ok)&!(no<->pets))"},
      # normalizes "nopets" to "!(pets<->ok)|(no<->pets)"
      {~r/\bnopets\b/i, "((no<->pets)|!(pets<->ok))"},
      # normalizes rental(s), also-for-rents and lease(s) to "for rent" (which is how these are indexed)
      {~r/\b(?:(?:also\s)?for\s)?(?:rentals?|rent|leases?)\b/i, "for<->rent"},
      # normalizes <-> and <number>
      {~r/\s*\<([0-9]+|-)\>\s*/, "<\\1>"},
      # normalizes quoted strings from "exact order" to exact<->order
      {~r/"\s*([^"]+?)\s*"/, fn _, phrase -> Regex.replace(~r/ +/, phrase, "<->") end},
      # ranges
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (room)s?/,
       fn _whole, start, finish, <<abbrev::bytes-3, _::binary>> ->
         "(" <>
           Enum.map_join(
             String.to_integer(start)..String.to_integer(finish),
             "|",
             &(to_string(&1) <> abbrev)
           ) <> ")"
       end},

      # normalizes "X-Y room" or "X-Y rooms" to "(Xroo|X+1roo|...|Yroo)"
      # normalizes "X-Y bedrooms" or "X-Y beds" or "X-Y bed" to "(Xbed|X+1bed|...|Ybed) (and same for bathrooms)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (?:(bed|bath))(?:room)?s?/i,
       fn _whole, start, finish, <<abbrev::bytes-3, _::binary>> ->
         "(" <>
           Enum.map_join(
             String.to_integer(start)..String.to_integer(finish),
             "|",
             &(to_string(&1) <> abbrev)
           ) <> ")"
       end},

      # normalizes "X-Y fireplace" or "X-Y fireplaces" to "(Xfir|X+1fir|...|Yfir)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (fireplace)s?/i,
       fn _whole, start, finish, <<abbrev::bytes-3, _::binary>> ->
         "(" <>
           Enum.map_join(
             String.to_integer(start)..String.to_integer(finish),
             "|",
             &(to_string(&1) <> abbrev)
           ) <> ")"
       end},

      # normalizes "X-Y skylight" or "X-Y skylights" to "(Xsky|X+1sky|...|Ysky)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (skylight)s?/i,
       fn _whole, start, finish, <<abbrev::bytes-3, _::binary>> ->
         "(" <>
           Enum.map_join(
             String.to_integer(start)..String.to_integer(finish),
             "|",
             &(to_string(&1) <> abbrev)
           ) <> ")"
       end},

      # normalizes "X-Y garage" or "X-Y garages" to "(Xgar|X+1gar|...|Ygar)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (garage)s?/i,
       fn _whole, start, finish, <<abbrev::bytes-3, _::binary>> ->
         "(" <>
           Enum.map_join(
             String.to_integer(start)..String.to_integer(finish),
             "|",
             &(to_string(&1) <> abbrev)
           ) <> ")"
       end},

      # normalizes "X-Y family" or "X-Y familys" (people misspell!) or "X-Y families" to "(Xfam|X+1fam|...|Yfam)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (familys?|families)/i,
       fn _whole, start, finish, <<abbrev::bytes-3, _::binary>> ->
         "(" <>
           Enum.map_join(
             String.to_integer(start)..String.to_integer(finish),
             "|",
             &(to_string(&1) <> abbrev)
           ) <> ")"
       end},

      # normalizes "X-Y story" or "X-Y storys" (people misspell!) or "X-Y stories" to "(Xsto|X+1sto|...|Ysto)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (storys?|stories)/i,
       fn _whole, start, finish, <<abbrev::bytes-3, _::binary>> ->
         "(" <>
           Enum.map_join(
             String.to_integer(start)..String.to_integer(finish),
             "|",
             &(to_string(&1) <> abbrev)
           ) <> ")"
       end},

      # normalizes "X room" or "X rooms" to "Xroo"
      {~r/\b([12]?[0-9]) (room)s?/i,
       fn _whole, num, <<abbrev::bytes-3, _::binary>> ->
         to_string(num) <> abbrev
       end},

      # normalizes "X bedrooms" or "X beds" or "X bed" to "Xbed" (and same for bathrooms, Xbat)
      {~r/\b([12]?[0-9]) (?:(bed|bath))(?:room)?s?/i,
       fn _whole, num, <<abbrev::bytes-3, _::binary>> ->
         to_string(num) <> abbrev
       end},

      # normalizes "X fireplace" or "X fireplaces" to "Xfir"
      {~r/\b([12]?[0-9]) (fireplace)s?/i,
       fn _whole, num, <<abbrev::bytes-3, _::binary>> ->
         to_string(num) <> abbrev
       end},

      # normalizes "X skylight" or "X skylights" to "Xsky"
      {~r/\b([12]?[0-9]) (skylight)s?/i,
       fn _whole, num, <<abbrev::bytes-3, _::binary>> ->
         to_string(num) <> abbrev
       end},

      # normalizes "X garage" or "X garages" to "Xgar"
      {~r/\b([12]?[0-9]) (garage)s?/i,
       fn _whole, num, <<abbrev::bytes-3, _::binary>> ->
         to_string(num) <> abbrev
       end},

      # normalizes "X family" or "X familys" (people misspell!) or "X families" to "Xfam"
      {~r/\b([12]?[0-9])(?: |\-)(familys?|families)/i,
       fn _whole, num, <<abbrev::bytes-3, _::binary>> ->
         to_string(num) <> abbrev
       end},

      # normalizes "X story" or "X storys" (people misspell!) or "X stories" to "Xsto"
      {~r/\b([12]?[0-9]) (storys?|stories)/i,
       fn _whole, num, <<abbrev::bytes-3, _::binary>> ->
         to_string(num) <> abbrev
       end},

      # normalizes "123 Story St., Manhasset" to "123 Story St. Manhasset" (removes commas)
      {~r/\s*\,\s*/, " "},

      # normalizes 'dr./drive', 'st./street', 'ln./lane', 'blvd./boulevard', 'ctr/center', 'cir/circle', 'ct/court', 'hts/heights',
      # 'fwy/freeway', 'hwy/highway', 'jct/junction', 'mnr/manor', 'mt/mount', 'pky/parkway', 'pl./place', 'pt./point',
      # 'rd./road', 'sq./square', 'sta./station', 'tpke/turnpike', 'ave./avenue' to be considered equivalent.
      # Abbreviation periods considered optional.
      {~r/\bdr(?:ive)?\b\.?/i, "(dr|drive)"},
      {~r/\bst(?:reet)?\b\.?/i, "(st|street)"},
      {~r/\b(?:ln|lane)\b\.?/i, "(ln|lane)"},
      {~r/\b(?:blvd|boulevard)\b\.?/i, "(blvd|boulevard)"},
      {~r/\b(?:ctr|center)\b/i, "(ctr|center)"},
      {~r/\bcir(?:cle)?\b/i, "(cir|circle)"},
      {~r/\b(?:ct|court)\b\.?/i, "(ct|court)"},
      {~r/\b(?:hts|heights)\b/i, "(hts|heights)"},
      {~r/\b(?:fwy|freeway)\b/i, "(fwy|freeway)"},
      {~r/\b(?:hwy|highway)\b/i, "(hwy|highway)"},
      {~r/\b(?:jct|junction)\b/i, "(jct|junction)"},
      {~r/\b(?:mnr|manor)\b/i, "(mnr|manor)"},
      {~r/\b(?:mt|mount)\b\.?/i, "(mt|mount)"},
      {~r/\b(?:pky|parkway)\b/i, "(pky|parkway)"},
      {~r/\bpl(?:ace)?\b\.?/i, "(pl|place)"},
      {~r/\b(?:pt|point)\b\.?/i, "(pt|point)"},
      {~r/\b(?:rd|road)\b\.?/i, "(rd|road)"},
      {~r/\bsq(?:uare|\.)?\b\.?/i, "(sq|square)"},
      {~r/\bsta(?:tion)?\b\.?/i, "(sta|station)"},
      {~r/\b(?:tpke|turnpike)\b/i, "(tpke|turnpike)"},
      {~r/\bave(?:nue)?\b\.?/i, "(ave|avenue)"},
      # normalizes "W,X,Y , Z" to "W|X|Y|Z"
      # This has been disabled due to wonky behavior with searches like this:
      # 123 Foo Bar, Town, State Zipcode
      # {~r/\s*\,\s*/, "|"},
      # normalizes "X and Y" or "X AND Y" to "X&Y"
      {~r/\s+and\s+/i, "&"},
      # normalizes "X or Y" or "X OR Y" to "X|Y"
      {~r/\s+or\s+/i, "|"},
      # normalizes  " &not" to "&!"
      {~r/\s*&not\b/i, "&!"},
      # normalizes " |not" to "|!"
      {~r/\s*\|not\b/i, "|!"},
      # normalizes a word boundary "not" plus 1 or more spaces to just "!"
      {~r/\bnot\s+/i, "!"},
      # removes spaces around any &
      {~r/\s*&\s*/, "&"},
      # removes spaces around any |
      {~r/\s*\|\s*/, "|"},
      # removes spaces after any !
      {~r/!\s+/, "!"},
      # trims leading and trailing spaces
      {~r/^\s+/, ""},
      {~r/\s+$/, ""},
      # finally, changes any remaining spaces to & (and's the rest) since spaces are not allowed
      {~r/\s+/, "&"}
    ]
  end

  defp normalize_query(q) do
    Enum.reduce(normalization_transformations(), String.trim(q), fn {regex, repl}, acc ->
      Regex.replace(regex, acc, repl)
    end)
  end

  # This is actual test code which is called from the test suite.
  # Put here for convenience to quickly test changes to the normalization_transformations() function above.
  # First element of tuple is the expected result, second element is the input.
  def test_normalize_query() do
    test_cases = [
      # This should not be processed as an ordinal, 29 is limit
      {"30&bedroom", "30 bedroom"},
      {"(2roo|3roo)", "2-3 rooms"},
      {"2roo", "2 rooms"},
      {"(2bed|3bed|4bed)", "2-4 bedrooms"},
      {"2bed", "2 bedroom"},
      {"(2bed|3bed)", "2-3 beds"},
      {"(2bed|3bed)", "2-3 bed"},
      {"(2bat|3bat)", "2-3 bathrooms"},
      {"2bat", "2 bathroom"},
      {"(2bed|3bed)&2bat", "2-3 bed 2 bath"},
      {"(2bat|3bat)", "2-3 baths"},
      {"(2bat|3bat)", "2-3 bath"},
      {"(2bat|3bat)&(2bed|3bed)", "2-3 bath 2-3 bed"},
      {"(2fir|3fir)", "2-3 fireplace"},
      {"3fir", "3 fireplaces"},
      {"(2sky|3sky)", "2-3 skylights"},
      {"3sky", "3 skylights"},
      {"(2gar|3gar)", "2-3 garage"},
      {"3gar", "3 garage"},
      {"(2fam|3fam)", "2-3 family"},
      {"2fam", "2 family"},
      {"10fam", "10-family"},
      {"(2sto|3sto)", "2-3 story"},
      {"(2sto|3sto)", "2-3 stories"},
      {"(2sto|3sto)", "2-3 storys"},
      {"(3bed|4bed|5bed)&cape&den", "3-5 beds cape den"},
      {"a|b", " a or b"},
      {"a&b", " a  b "},
      {"a&!b", "a not b"},
      {"a&!b", "a and not b"},
      {"a|!b", "a or !b"},
      {"a&!b", "a ! b"},
      {"a<->b|c", "\"a b\" or c"},
      {"yabba<->dabba<->do&barney", " \" yabba  dabba do  \"  barney "},
      {"a<->b|c<->d", "\"a b\" |\"c d\""},
      {"a<2>b", " a  <2> b"},
      {"!b", "not b"},
      # I'm disabling comma-delimited values being treated as OR's for now
      # because this behaves wonky with comma-fied addresses
      # {"W|X|Y|Z", "W,X,Y,Z"},
      # instead all commas will simply be removed and ignored for now
      {"W&X&Y&Z", "W, X,Y ,Z,"},
      {"123&Story&(ave|avenue)&Manhasset&NY", "123 Story Ave., Manhasset, NY"},
      {"for<->rent", "also for rent"},
      {"for<->rent", "leases"},
      {"for<->rent", "rentals"}
    ]

    for {expected, input} <- test_cases, do: ^expected = normalize_query(input)
    true
  end

  defp search_all_fields_using_postgres_fulltext_search({q, scope, errors}) do
    something_left = if String.trim(q) != "", do: true, else: false
    q = if something_left, do: normalize_query(q), else: q

    scope =
      if something_left do
        scope
        |> where([l], fragment("search_vector @@ to_tsquery('english_nostop', ?)", ^q))
        |> order_by([l],
          asc: fragment("ts_rank_cd(search_vector, to_tsquery('english_nostop', ?), 32)", ^q)
        )
      else
        scope
      end

    {q, scope, errors}
  end

  # defp _search_all_fields(q) do
  #   q = String.downcase(q) # index is on the lower(fieldname) of all fields
  #   like_query = "%#{q}%"
  #   Repo.all(from l in Listing, where:
  #        like(fragment("lower(?)", l.address), ^like_query)
  #     or like(fragment("lower(?)", l.description), ^like_query)
  #     or like(fragment("lower(?)", l.remarks), ^like_query)
  #     or like(fragment("lower(?)", l.association), ^like_query)
  #     or like(fragment("lower(?)", l.neighborhood), ^like_query)
  #     or like(fragment("lower(?)", l.schools), ^like_query)
  #     or like(fragment("lower(?)", l.zoning), ^like_query)
  #     or like(fragment("lower(?)", l.district), ^like_query)
  #     or like(fragment("lower(?)", l.construction), ^like_query)
  #     or like(fragment("lower(?)", l.appearance), ^like_query)
  #     or like(fragment("lower(?)", l.cross_street), ^like_query)
  #     or like(fragment("lower(?)", l.owner_name), ^like_query),
  #     order_by: [desc: l.updated_at], limit: 30 )
  #   |> Repo.preload([:broker, :user])
  # end

end
