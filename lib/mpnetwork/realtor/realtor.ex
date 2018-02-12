defmodule Mpnetwork.Realtor do
  @moduledoc """
  The boundary for the Realtor system.
  """

  import Ecto.Query, warn: false

  alias Mpnetwork.Realtor.{Broadcast, Listing, Office}
  alias Mpnetwork.{Repo, User, Permissions}

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{email: "test@example.com"})
      {:ok, %User{}}

      iex> create_user(%{email: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(
      from u in User,
      join: o in assoc(u, :broker),
      preload: [broker: o],
      order_by: [asc: o.name, asc: o.city, asc: u.name]
    )
  end

  def list_users(nil) do
    list_users()
    # Repo.all(
    #   from u in User,
    #   order_by: [asc: u.name]
    # )
  end

  def list_users(office) do
    Repo.all(
      from u in User,
      join: o in assoc(u, :broker),
      preload: [broker: o],
      where: u.office_id == ^office.id,
      order_by: [asc: u.name]
    )
  end

  @doc """
  Returns the list of broadcasts.

  ## Examples

      iex> list_broadcasts()
      [%Broadcast{}, ...]

  """
  def list_broadcasts do
    Repo.all(Broadcast) #|> Repo.preload(:user)
  end

  @doc """
  Returns the last N broadcasts, sorted descending.

  ## Examples

      iex> list_latest_broadcasts()
      [%Broadcast{}, ...]

  """
  def list_latest_broadcasts(count \\ 5) do
    Repo.all(from b in Broadcast, order_by: [desc: b.inserted_at], limit: ^count) |> Repo.preload(:user)
  end

  @doc """
  Gets a single broadcast.

  Raises `Ecto.NoResultsError` if the Broadcast does not exist.

  ## Examples

      iex> get_broadcast!(123)
      %Broadcast{}

      iex> get_broadcast!(456)
      ** (Ecto.NoResultsError)

  """
  def get_broadcast!(id) do
    Repo.get!(Broadcast, id) #|> Repo.preload(:user)
  end

  def get_broadcast_with_user!(id) do
    Repo.get!(Broadcast, id) |> Repo.preload(:user)
  end

  @doc """
  Creates a broadcast.

  ## Examples

      iex> create_broadcast(%{field: value})
      {:ok, %Broadcast{}}

      iex> create_broadcast(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_broadcast(attrs \\ %{}) do
    %Broadcast{}
    |> Broadcast.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a broadcast.

  ## Examples

      iex> update_broadcast(broadcast, %{field: new_value})
      {:ok, %Broadcast{}}

      iex> update_broadcast(broadcast, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_broadcast(%Broadcast{} = broadcast, attrs) do
    broadcast
    |> Broadcast.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Broadcast.

  ## Examples

      iex> delete_broadcast(broadcast)
      {:ok, %Broadcast{}}

      iex> delete_broadcast(broadcast)
      {:error, %Ecto.Changeset{}}

  """
  def delete_broadcast(%Broadcast{} = broadcast) do
    Repo.delete(broadcast)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking broadcast changes.

  ## Examples

      iex> change_broadcast(broadcast)
      %Ecto.Changeset{source: %Broadcast{}}

  """
  def change_broadcast(%Broadcast{} = broadcast) do
    Broadcast.changeset(broadcast, %{})
  end

  alias Mpnetwork.Realtor.Listing

  @doc """
  Returns the list of listings.

  ## Examples

      iex> list_listings()
      [%Listing{}, ...]

  """
  def list_listings(realtor, limit \\ 30) do
    list_latest_listings(realtor, limit)
  end


  def list_latest_listings(who, limit \\ 5)

  @doc """
  Returns the latest non-draft listings by everyone

  ## Examples

      iex> list_latest_listings(current_user, 5)
      [%Listing{}, ...]

  """
  def list_latest_listings(nil, limit) do
    Repo.all(from l in Listing, where: l.draft == false, order_by: [desc: l.updated_at], limit: ^limit, preload: [:broker, :user])
  end

  @doc """
  Returns the latest non-draft listings, including this user's draft listings

  ## Examples

      iex> list_latest_listings()
      [%Listing{}, ...]

  """
  def list_latest_listings(%User{} = current_user, limit) do
    Repo.all(from l in Listing, where: l.draft == false or l.user_id == ^current_user.id, order_by: [desc: l.updated_at], limit: ^limit, preload: [:broker, :user])
  end

  def list_latest_draft_listings(%User{} = current_user) do
    Repo.all(from l in Listing, where: l.user_id == ^current_user.id and l.draft == true, order_by: [desc: l.updated_at], limit: 20, preload: [:broker, :user])
  end

  def list_latest_draft_listings(%Office{} = current_office) do
    Repo.all(from l in Listing, where: l.broker_id == ^current_office.id and l.draft == true, order_by: [desc: l.updated_at], limit: 20, preload: [:broker, :user])
  end

  def list_latest_listings_excluding_new(nil, limit \\ 15) do
    Repo.all(from l in Listing, where: (l.draft == false) and (l.inserted_at != l.updated_at), order_by: [desc: l.updated_at], limit: ^limit, preload: [:broker, :user])
  end

  def list_most_recently_created_listings(nil, limit \\ 30) do
    day_to_filter_after = Timex.shift(NaiveDateTime.utc_now, days: -7)
    Repo.all(from l in Listing, where: (l.draft == false) and l.inserted_at >= ^day_to_filter_after, order_by: [desc: l.inserted_at], limit: ^limit, preload: [:broker, :user])
  end

  def list_most_recently_visible_listings(nil, limit \\ 30) do
    today = Date.utc_today
    day_to_filter_after = NaiveDateTime.to_date(Timex.shift(NaiveDateTime.utc_now, days: -7))
    Repo.all(from l in Listing, where: (l.draft == false) and l.visible_on >= ^day_to_filter_after and l.visible_on <= ^today, order_by: [desc: l.visible_on], limit: ^limit, preload: [:broker, :user])
  end

  # Updates listings with expires_on in the local timezone past to be listing_status_type "EXP"
  # but only if it was any of the following listing_status_type's to begin with:
  # "NEW", "FS", "EXT", "PC", "TOM"
  def update_expired_listings(delay \\ 1000) do
    :timer.sleep(delay) # Just to make sure it's definitely after midnight if this job runs at exactly midnight EST
    local_date_now = Timex.now("America/New_York") |> Timex.to_date
    from(
      l in Listing,
      where: l.expires_on < ^local_date_now,
      where: l.listing_status_type in ~w[NEW FS EXT PC TOM],
      update: [set: [listing_status_type: "EXP"]]
    )
    |> Repo.update_all([])
    # NOTE: Does NOT update updated_at (which is good in this case)
    # but DOES update the search index via trigger (which is also good in this case)
  end

  @doc """
  Returns the next N listings with upcoming broker open houses.

  ## Examples

      iex> list_next_broker_oh_listings()
      [%Listing{}, ...]

  """
  def list_next_broker_oh_listings(_, _, _after_datetime \\ nil)
  def list_next_broker_oh_listings(nil, number, after_datetime) do
    now = after_datetime || NaiveDateTime.utc_now
    now = now |> Timex.shift(hours: -4) |> Timex.to_naive_datetime # so 9am inspections still show up on sheet at 1pm (but not later)
    Repo.all(from l in Listing, where: l.first_broker_oh_start_at > ^now and l.draft == false, or_where: l.second_broker_oh_start_at > ^now and l.draft == false, order_by: [asc: l.first_broker_oh_start_at, asc: l.second_broker_oh_start_at], limit: ^number, preload: [:broker, :user])
  end
  # def list_next_broker_oh_listings(current_user, number, after_datetime) do
  #   now = after_datetime || NaiveDateTime.utc_now
  #   now = now |> Timex.shift(hours: -4) |> Timex.to_naive_datetime # so 9am inspections still show up on sheet at 1pm (but not later)
  #   Repo.all(from l in Listing, where: l.first_broker_oh_start_at > ^now and l.draft == false, or_where: l.second_broker_oh_start_at > ^now and l.draft == false, order_by: [asc: l.first_broker_oh_start_at, asc: l.second_broker_oh_start_at], limit: ^number, preload: [:broker, :user])
  # end

  def list_next_cust_oh_listings(_, _, _after_datetime \\ nil)
  def list_next_cust_oh_listings(nil, number, after_datetime) do
    now = after_datetime || NaiveDateTime.utc_now
    now = now |> Timex.shift(hours: -4) |> Timex.to_naive_datetime # so 9am open houses still show up on sheet at 1pm (but not later)
    Repo.all(from l in Listing, where: l.first_cust_oh_start_at > ^now and l.draft == false, or_where: l.second_cust_oh_start_at > ^now and l.draft == false, order_by: [asc: l.first_cust_oh_start_at, asc: l.second_cust_oh_start_at], limit: ^number, preload: [:broker, :user])
  end

  defp default_search_scope(current_user) do
    if Permissions.office_admin_or_site_admin?(current_user) do
      if Permissions.office_admin?(current_user) do
        current_office = get_office!(current_user.office_id)
        from l in Listing, where: l.draft == false or l.broker_id == ^current_office.id, order_by: [desc: l.updated_at], preload: [:broker, :user], limit: 50
      else # site admin
        from l in Listing, order_by: [desc: l.updated_at], preload: [:broker, :user], limit: 100
      end
    else # regular realtor
      from l in Listing, where: l.draft == false or l.user_id == ^current_user.id, order_by: [desc: l.updated_at], preload: [:broker, :user], limit: 50
    end
  end

  @doc """
  Queries listings.
  """
  def query_listings("", current_user) do
    {Repo.all(default_search_scope(current_user) |> where([l], (l.listing_status_type in ~w[NEW FS EXT PC]))), []}
  end
  def query_listings(query, current_user) do
    {_consumed_query, final_scope, errors} = {query, default_search_scope(current_user), []}
      |> try_id() # should return {"unconsumed_query", new_scope, any_errors} ... down the line
      |> try_my_office(current_user)
      |> try_mine(current_user)
      |> try_pricerange()
      |> try_daterange()
      |> try_active_inactive()
      |> try_listing_status_type()
      |> search_all_fields_using_postgres_fulltext_search()
    listings = Repo.all(final_scope)
    {listings, errors}
  end

  defp try_id({query, scope, errors}) do
    if _try_zipcode({query, scope, errors}) do
      {query, scope, errors}
    else
      id = _try_integer(query)
      if id do
        {"", scope |> where([l], l.id == ^id), errors}
      else
        {query, scope, errors}
      end
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
  @zipcode_regex ~r/\b11[0-9]{3}\b/
  defp _try_zipcode({query, _scope, _errors}) do
    Regex.match?(@zipcode_regex, query)
  end


  defp convert_binary_date_parts_to_date_struct(year, month, day) when is_binary(year) and is_binary(month) and is_binary(day) do
    case Date.new(_try_integer(year), _try_integer(month), _try_integer(day)) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  @my_office_regex ~r/ ?\bmy office\b ?/i
  defp try_my_office({query, scope, errors}, current_user) do
    if Regex.match?(@my_office_regex, query) do
      current_office = get_office!(current_user.office_id)
      {Regex.replace(@my_office_regex, query, ""), scope |> where([l], l.broker_id == ^current_office.id), errors}
    else
      {query, scope, errors}
    end
  end

  @mine_regex ~r/ ?\b(?:my|mine)\b ?/i
  defp try_mine({query, scope, errors}, current_user) do
    if Regex.match?(@mine_regex, query) do
      {Regex.replace(@mine_regex, query, ""), scope |> where([l], l.user_id == ^current_user.id), errors}
    else
      {query, scope, errors}
    end
  end

  @pricerange_regex ~r/\$?([0-9,]{3,}) ?\- ?\$?([0-9,]{3,})/
  defp try_pricerange({query, scope, errors}) do
    pr = case Regex.run(@pricerange_regex, query) do
      [_, start, finish] -> {_filter_nonnumeric(start), _filter_nonnumeric(finish)}
      _ -> nil
    end
    if pr do
      {start, finish} = pr
      {Regex.replace(@pricerange_regex, query, ""), scope |> where([l], (l.price_usd >= ^start and l.price_usd <= ^finish) or (l.rental_price_usd >= ^start and l.rental_price_usd <= ^finish)), errors}
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

  defp _process_daterangesearch({query, scope, errors}, :FS, regex, {start_yr, start_mon, start_day}, {finish_yr, finish_mon, finish_day}) do
    valid_startday = convert_binary_date_parts_to_date_struct(start_yr, start_mon, start_day)
    valid_finishday = convert_binary_date_parts_to_date_struct(finish_yr, finish_mon, finish_day)
    cond do
      valid_startday && valid_finishday -> {Regex.replace(regex, query, ""), scope |> where([l], (l.visible_on >= ^valid_startday and l.visible_on <= ^valid_finishday)), errors}
      !valid_startday && valid_finishday -> {Regex.replace(regex, query, ""), scope, ["Invalid start day in Listing Date search range: #{start_mon}/#{start_day}/#{start_yr}" | errors]}
      valid_startday && !valid_finishday -> {Regex.replace(regex, query, ""), scope, ["Invalid end day in Listing Date search range: #{finish_mon}/#{finish_day}/#{finish_yr}" | errors]}
      true -> {Regex.replace(regex, query, ""), scope, ["Dates are both invalid in Listing Date search range: #{start_mon}/#{start_day}/#{start_yr}-#{finish_mon}/#{finish_day}/#{finish_yr}" | errors]}
    end
  end

  defp _process_daterangesearch({query, scope, errors}, :UC, regex, {start_yr, start_mon, start_day}, {finish_yr, finish_mon, finish_day}) do
    valid_startday = convert_binary_date_parts_to_date_struct(start_yr, start_mon, start_day)
    valid_finishday = convert_binary_date_parts_to_date_struct(finish_yr, finish_mon, finish_day)
    cond do
      valid_startday && valid_finishday -> {Regex.replace(regex, query, ""), scope |> where([l], (l.uc_on >= ^valid_startday and l.uc_on <= ^valid_finishday)), errors}
      !valid_startday && valid_finishday -> {Regex.replace(regex, query, ""), scope, ["Invalid start day in Under Contract date search range: #{start_mon}/#{start_day}/#{start_yr}" | errors]}
      valid_startday && !valid_finishday -> {Regex.replace(regex, query, ""), scope, ["Invalid end day in Under Contract date search range: #{finish_mon}/#{finish_day}/#{finish_yr}" | errors]}
      true -> {Regex.replace(regex, query, ""), scope, ["Dates are both invalid in Under Contract date search range: #{start_mon}/#{start_day}/#{start_yr}-#{finish_mon}/#{finish_day}/#{finish_yr}" | errors]}
    end
  end

  defp _process_daterangesearch({query, scope, errors}, :CL, regex, {start_yr, start_mon, start_day}, {finish_yr, finish_mon, finish_day}) do
    valid_startday = convert_binary_date_parts_to_date_struct(start_yr, start_mon, start_day)
    valid_finishday = convert_binary_date_parts_to_date_struct(finish_yr, finish_mon, finish_day)
    cond do
      valid_startday && valid_finishday -> {Regex.replace(regex, query, ""), scope |> where([l], (l.closed_on >= ^valid_startday and l.closed_on <= ^valid_finishday)), errors}
      !valid_startday && valid_finishday -> {Regex.replace(regex, query, ""), scope, ["Invalid start day in Closing Date search range: #{start_mon}/#{start_day}/#{start_yr}" | errors]}
      valid_startday && !valid_finishday -> {Regex.replace(regex, query, ""), scope, ["Invalid end day in Closing Date search range: #{finish_mon}/#{finish_day}/#{finish_yr}" | errors]}
      true -> {Regex.replace(regex, query, ""), scope, ["Dates are both invalid in Closing Date search range: #{start_mon}/#{start_day}/#{start_yr}-#{finish_mon}/#{finish_day}/#{finish_yr}" | errors]}
    end
  end

  defp try_daterange({query, scope, errors}) do
    {query, scope, errors} = case Regex.run(@daterange_fs_regex, query) do
      [_, start_mon, start_day, start_yr, finish_mon, finish_day, finish_yr] -> _process_daterangesearch({query, scope, errors}, :FS, @daterange_fs_regex, {start_yr, start_mon, start_day}, {finish_yr, finish_mon, finish_day})
      _ -> {query, scope, errors}
    end
    {query, scope, errors} = case Regex.run(@daterange_uc_regex, query) do
      [_, start_mon, start_day, start_yr, finish_mon, finish_day, finish_yr] -> _process_daterangesearch({query, scope, errors}, :UC, @daterange_uc_regex, {start_yr, start_mon, start_day}, {finish_yr, finish_mon, finish_day})
      _ -> {query, scope, errors}
    end
    {query, scope, errors} = case Regex.run(@daterange_cl_regex, query) do
      [_, start_mon, start_day, start_yr, finish_mon, finish_day, finish_yr] -> _process_daterangesearch({query, scope, errors}, :CL, @daterange_cl_regex, {start_yr, start_mon, start_day}, {finish_yr, finish_mon, finish_day})
      _ -> {query, scope, errors}
    end
    {query, scope, errors}
  end

  # If you search on a capitalized listing status, replace with specifically-indexed listing status word "lst/<listing_status>"
  @listing_status_type_regex ~r/\b(NEW|FS|EXT|UC|CL|PC|WR|TOM|EXP)\b/
  defp try_listing_status_type({query, scope, errors}) do
    query = Regex.replace(@listing_status_type_regex, query, "lst/\\1")
    {query, scope, errors}
  end

  # Default to active listing statuses unless the word "inactive" or "unavailable" is used, for ease
  # OR if a specific listing status type is used at all, do not add the default active scope
  @active_regex ~r/\b(?:active|available)\b/i
  @inactive_regex ~r/\b(?:inactive|unavailable)\b/i
  @all_regex ~r/\ball\b/i
  @expired_regex ~r/\bexpired\b/i
  defp try_active_inactive({query, scope, errors}) do
    if Regex.match?(@all_regex, query) or Regex.match?(@listing_status_type_regex, query) or Regex.match?(@expired_regex, query) do
      # just pass it through
      {Regex.replace(@all_regex, query, ""), scope, errors}
    else
      if Regex.match?(@inactive_regex, query) do
        {Regex.replace(@inactive_regex, query, ""), scope |> where([l], (l.listing_status_type in ~w[CL WR TOM EXP])), errors}
      else
        {Regex.replace(@active_regex, query, ""), scope |> where([l], (l.listing_status_type in ~w[NEW FS EXT PC])), errors}
      end
    end
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
      {~r/\s*\<([0-9]+|-)\>\s*/, "<\\1>"}, # normalizes <-> and <number>
      {~r/"\s*([^"]+?)\s*"/, fn _, phrase -> Regex.replace(~r/ +/, phrase, "<->") end}, # normalizes quoted strings from "exact order" to exact<->order
      # ranges
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (room)s?/,
        fn(_whole, start, finish, <<abbrev::bytes-3, _::binary>>) ->
          "(" <> Enum.map_join(String.to_integer(start)..String.to_integer(finish), "|", &(to_string(&1) <> abbrev)) <> ")"
        end
      }, # normalizes "X-Y room" or "X-Y rooms" to "(Xroo|X+1roo|...|Yroo)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (?:(bed|bath))(?:room)?s?/,
        fn(_whole, start, finish, <<abbrev::bytes-3, _::binary>>) ->
          "(" <> Enum.map_join(String.to_integer(start)..String.to_integer(finish), "|", &(to_string(&1) <> abbrev)) <> ")"
        end
      }, # normalizes "X-Y bedrooms" or "X-Y beds" or "X-Y bed" to "(Xbed|X+1bed|...|Ybed) (and same for bathrooms)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (fireplace)s?/,
        fn(_whole, start, finish, <<abbrev::bytes-3, _::binary>>) ->
          "(" <> Enum.map_join(String.to_integer(start)..String.to_integer(finish), "|", &(to_string(&1) <> abbrev)) <> ")"
        end
      }, # normalizes "X-Y fireplace" or "X-Y fireplaces" to "(Xfir|X+1fir|...|Yfir)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (skylight)s?/,
        fn(_whole, start, finish, <<abbrev::bytes-3, _::binary>>) ->
          "(" <> Enum.map_join(String.to_integer(start)..String.to_integer(finish), "|", &(to_string(&1) <> abbrev)) <> ")"
        end
      }, # normalizes "X-Y skylight" or "X-Y skylights" to "(Xsky|X+1sky|...|Ysky)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (garage)s?/,
        fn(_whole, start, finish, <<abbrev::bytes-3, _::binary>>) ->
          "(" <> Enum.map_join(String.to_integer(start)..String.to_integer(finish), "|", &(to_string(&1) <> abbrev)) <> ")"
        end
      }, # normalizes "X-Y garage" or "X-Y garages" to "(Xgar|X+1gar|...|Ygar)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (familys?|families)/,
        fn(_whole, start, finish, <<abbrev::bytes-3, _::binary>>) ->
          "(" <> Enum.map_join(String.to_integer(start)..String.to_integer(finish), "|", &(to_string(&1) <> abbrev)) <> ")"
        end
      }, # normalizes "X-Y family" or "X-Y familys" (people misspell!) or "X-Y families" to "(Xfam|X+1fam|...|Yfam)"
      {~r/\b([12]?[0-9]) ?\- ?\b([12]?[0-9]) (storys?|stories)/,
        fn(_whole, start, finish, <<abbrev::bytes-3, _::binary>>) ->
          "(" <> Enum.map_join(String.to_integer(start)..String.to_integer(finish), "|", &(to_string(&1) <> abbrev)) <> ")"
        end
      }, # normalizes "X-Y story" or "X-Y storys" (people misspell!) or "X-Y stories" to "(Xsto|X+1sto|...|Ysto)"
      # singles
      {~r/\b([12]?[0-9]) (room)s?/,
        fn(_whole, num, <<abbrev::bytes-3, _::binary>>) ->
          to_string(num) <> abbrev
        end
      }, # normalizes "X room" or "X rooms" to "Xroo"
      {~r/\b([12]?[0-9]) (?:(bed|bath))(?:room)?s?/,
        fn(_whole, num, <<abbrev::bytes-3, _::binary>>) ->
          to_string(num) <> abbrev
        end
      }, # normalizes "X bedrooms" or "X beds" or "X bed" to "Xbed" (and same for bathrooms, Xbat)
      {~r/\b([12]?[0-9]) (fireplace)s?/,
        fn(_whole, num, <<abbrev::bytes-3, _::binary>>) ->
          to_string(num) <> abbrev
        end
      }, # normalizes "X fireplace" or "X fireplaces" to "Xfir"
      {~r/\b([12]?[0-9]) (skylight)s?/,
        fn(_whole, num, <<abbrev::bytes-3, _::binary>>) ->
          to_string(num) <> abbrev
        end
      }, # normalizes "X skylight" or "X skylights" to "Xsky"
      {~r/\b([12]?[0-9]) (garage)s?/,
        fn(_whole, num, <<abbrev::bytes-3, _::binary>>) ->
          to_string(num) <> abbrev
        end
      }, # normalizes "X garage" or "X garages" to "Xgar"
      {~r/\b([12]?[0-9])(?: |\-)(familys?|families)/,
        fn(_whole, num, <<abbrev::bytes-3, _::binary>>) ->
          to_string(num) <> abbrev
        end
      }, # normalizes "X family" or "X familys" (people misspell!) or "X families" to "Xfam"
      {~r/\b([12]?[0-9]) (storys?|stories)/,
        fn(_whole, num, <<abbrev::bytes-3, _::binary>>) ->
          to_string(num) <> abbrev
        end
      }, # normalizes "X story" or "X storys" (people misspell!) or "X stories" to "Xsto"
      {~r/\.\,\s/, ". "}, # normalizes "123 Story St., Manhasset" to "123 Story St. Manhasset" (removes comma which was screwing up the below)
      {~r/\s*\,\s*/, "|"}, # normalizes "W,X,Y , Z" to "W|X|Y|Z"
      {~r/\s+and\s+/i, "&"}, # normalizes "X and Y" or "X AND Y" to "X&Y"
      {~r/\s+or\s+/i, "|"}, # normalizes "X or Y" or "X OR Y" to "X|Y"
      {~r/\s*&not\b/i, "&!"}, # normalizes  " &not" to "&!"
      {~r/\s*\|not\b/i, "|!"}, # normalizes " |not" to "|!"
      {~r/\bnot\s+/i, "!"}, # normalizes a word boundary "not" plus 1 or more spaces to just "!"
      {~r/\s*&\s*/, "&"}, # removes spaces around any &
      {~r/\s*\|\s*/, "|"}, # removes spaces around any |
      {~r/!\s+/, "!"}, # removes spaces after any !
      {~r/\s+/, "&"}, # finally, changes any remaining spaces to & (and's the rest) since spaces are not allowed
    ]
  end

  defp normalize_query(q) do
    Enum.reduce(normalization_transformations(), String.trim(q), fn({regex, repl}, acc) -> Regex.replace(regex, acc, repl) end)
  end

  # This is actual test code which is called from the test suite.
  # Put here for convenience to quickly test changes to the normalization_transformations() function above.
  # First element of tuple is the expected result, second element is the input.
  def test_normalize_query() do
    test_cases = [
      {"30&bedroom", "30 bedroom"}, # This should not be processed as an ordinal, 29 is limit
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
      {"a|b"," a or b"},
      {"a&b"," a  b "},
      {"a&!b","a not b"},
      {"a&!b","a and not b"},
      {"a|!b","a or !b"},
      {"a&!b","a ! b"},
      {"a<->b|c","\"a b\" or c"},
      {"yabba<->dabba<->do&barney", " \" yabba  dabba do  \"  barney "},
      {"a<->b|c<->d", "\"a b\" |\"c d\""},
      {"a<2>b"," a  <2> b"},
      {"!b","not b"},
      {"W|X|Y|Z", "W, X,Y , Z"},
      {"123&Story&Ave.&Manhasset", "123 Story Ave., Manhasset"},
    ]
    for {expected, input} <- test_cases, do: ^expected = normalize_query(input)
    true
  end

  defp search_all_fields_using_postgres_fulltext_search({q, scope, errors}) do
    scope = if String.trim(q) != "" do
      q = normalize_query(q)
      scope
      |> where([l], fragment("search_vector @@ to_tsquery(?)", ^q))
      |> order_by([l], [asc: fragment("ts_rank_cd(search_vector, to_tsquery(?), 32)", ^q)])
    else
      scope
    end
    {"", scope, errors}
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

  @doc """
  Gets a single listing.

  Raises `Ecto.NoResultsError` if the Listing does not exist.

  ## Examples

      iex> get_listing!(123)
      %Listing{}

      iex> get_listing!(456)
      ** (Ecto.NoResultsError)

  """
  def get_listing!(id), do: Repo.get!(Listing, id) |> Repo.preload([:broker, :user])

  @doc """
  Gets a list of listings based on a list of ID's.

  Returns empty list if no matches.

  ## Examples

      iex> get_listings([123])
      [%Listing{}]

      iex> get_listings([456, 789])
      []

  """
  def get_listings(ids) when is_list(ids) do
    Repo.all(from l in Listing, where: l.id in ^ids, order_by: [desc: l.updated_at]) |> Repo.preload([:broker, :user])
  end

  @doc """
  Creates a listing.

  ## Examples

      iex> create_listing(%{field: value})
      {:ok, %Listing{}}

      iex> create_listing(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_listing(attrs \\ %{}) do
    %Listing{}
    |> Listing.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a listing.

  ## Examples

      iex> update_listing(listing, %{field: new_value})
      {:ok, %Listing{}}

      iex> update_listing(listing, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_listing(%Listing{} = listing, attrs) do
    listing
    |> Listing.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Listing.

  ## Examples

      iex> delete_listing(listing)
      {:ok, %Listing{}}

      iex> delete_listing(listing)
      {:error, %Ecto.Changeset{}}

  """
  def delete_listing(%Listing{} = listing) do
    Repo.delete(listing)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking listing changes.

  ## Examples

      iex> change_listing(listing)
      %Ecto.Changeset{source: %Listing{}}

  """
  def change_listing(%Listing{} = listing) do
    Listing.changeset(listing, %{})
  end

  @doc """
  Returns a list of all office names with their id's.
  """
  def all_office_names do
    Repo.all(
      from office in Office,
      select: {office.id, office.name},
      order_by: [asc: office.name]
    )
  end

  @doc """
  Returns the list of offices.

  ## Examples

      iex> list_offices()
      [%Office{}, ...]

  """
  def list_offices do
    Repo.all(
      from office in Office,
      order_by: [asc: office.name]
    )
  end

  @doc """
  Gets a single office.

  Raises `Ecto.NoResultsError` if the Office does not exist.

  ## Examples

      iex> get_office!(123)
      %Office{}

      iex> get_office!(456)
      ** (Ecto.NoResultsError)

  """
  def get_office!(id), do: Repo.get!(Office, id)

  @doc """
  Creates a office.

  ## Examples

      iex> create_office(%{field: value})
      {:ok, %Office{}}

      iex> create_office(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_office(attrs \\ %{}) do
    %Office{}
    |> Office.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a office.

  ## Examples

      iex> update_office(office, %{field: new_value})
      {:ok, %Office{}}

      iex> update_office(office, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_office(%Office{} = office, attrs) do
    office
    |> Office.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Office.

  ## Examples

      iex> delete_office(office)
      {:ok, %Office{}}

      iex> delete_office(office)
      {:error, %Ecto.Changeset{}}

  """
  def delete_office(%Office{} = office) do
    Repo.delete(office)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking office changes.

  ## Examples

      iex> change_office(office)
      %Ecto.Changeset{source: %Office{}}

  """
  def change_office(%Office{} = office) do
    Office.changeset(office, %{})
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id) |> Repo.preload(:broker)

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
