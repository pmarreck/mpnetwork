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
      from(
        u in User,
        join: o in assoc(u, :broker),
        preload: [broker: o],
        order_by: [asc: o.name, asc: o.city, asc: u.name]
      )
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
      from(
        u in User,
        join: o in assoc(u, :broker),
        preload: [broker: o],
        where: u.office_id == ^office.id,
        order_by: [asc: u.name]
      )
    )
  end

  @doc """
  Returns the list of locked users.

  ## Examples

      iex> list_locked_users()
      [%User{}, ...]

  """
  def list_locked_users do
    Repo.all(
      from(
        u in User,
        join: o in assoc(u, :broker),
        preload: [broker: o],
        where: not(is_nil(u.locked_at)) and u.failed_attempts > 0,
        order_by: [asc: o.name, asc: o.city, asc: u.name]
      )
    )
  end

  def list_locked_users(nil), do: list_locked_users()

  def list_locked_users(office) do
    Repo.all(
      from(
        u in User,
        join: o in assoc(u, :broker),
        preload: [broker: o],
        where: u.office_id == ^office.id,
        where: not(is_nil(u.locked_at)) and u.failed_attempts > 0,
        order_by: [asc: u.name]
      )
    )
  end

  @doc """
  Returns the list of broadcasts.

  ## Examples

      iex> list_broadcasts()
      [%Broadcast{}, ...]

  """
  def list_broadcasts do
    # |> Repo.preload(:user)
    Repo.all(Broadcast)
  end

  @doc """
  Returns the last N broadcasts, sorted descending.

  ## Examples

      iex> list_latest_broadcasts()
      [%Broadcast{}, ...]

  """
  def list_latest_broadcasts(max \\ 5) do
    Repo.all(from(b in Broadcast, order_by: [desc: b.inserted_at], limit: ^max))
    |> Repo.preload(:user)
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
    # |> Repo.preload(:user)
    Repo.get!(Broadcast, id)
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
    Repo.all(
      from(
        l in Listing,
        where: l.draft == false,
        order_by: [desc: l.updated_at],
        limit: ^limit,
        preload: [:broker, :user]
      )
    )
  end

  @doc """
  Returns the latest non-draft listings, including this user's draft listings

  ## Examples

      iex> list_latest_listings()
      [%Listing{}, ...]

  """
  def list_latest_listings(%User{} = current_user, limit) do
    Repo.all(
      from(
        l in Listing,
        where: l.draft == false or l.user_id == ^current_user.id,
        order_by: [desc: l.updated_at],
        limit: ^limit,
        preload: [:broker, :user]
      )
    )
  end

  def list_latest_draft_listings(%User{} = current_user) do
    Repo.all(
      from(
        l in Listing,
        where: l.user_id == ^current_user.id and l.draft == true,
        order_by: [desc: l.updated_at],
        limit: 20,
        preload: [:broker, :user]
      )
    )
  end

  def list_latest_draft_listings(%Office{} = current_office) do
    Repo.all(
      from(
        l in Listing,
        where: l.broker_id == ^current_office.id and l.draft == true,
        order_by: [desc: l.updated_at],
        limit: 20,
        preload: [:broker, :user]
      )
    )
  end

  def list_latest_listings_excluding_new(nil, limit \\ 15) do
    Repo.all(
      from(
        l in Listing,
        where: l.draft == false and l.inserted_at != l.updated_at,
        order_by: [desc: l.updated_at],
        limit: ^limit,
        preload: [:broker, :user]
      )
    )
  end

  def list_most_recently_created_listings(nil, limit \\ 30) do
    day_to_filter_after = Timex.shift(NaiveDateTime.utc_now(), days: -7)

    Repo.all(
      from(
        l in Listing,
        where: l.draft == false and l.inserted_at >= ^day_to_filter_after,
        order_by: [desc: l.inserted_at],
        limit: ^limit,
        preload: [:broker, :user]
      )
    )
  end

  def list_most_recently_visible_listings(nil, limit \\ 30) do
    today = DateTime.utc_now()
    day_to_filter_after = Timex.shift(today, days: -7)

    Repo.all(
      from(
        l in Listing,
        where: l.draft == false and l.live_at >= ^day_to_filter_after and l.live_at <= ^today,
        order_by: [desc: l.live_at],
        limit: ^limit,
        preload: [:broker, :user]
      )
    )
  end

  # Updates listings with expires_on in the local timezone past to be listing_status_type "EXP"
  # but only if it was any of the following listing_status_type's to begin with:
  # "NEW", "FS", "EXT", "PC", "TOM"
  def update_expired_listings(delay \\ 1000) do
    # Just to make sure it's definitely after midnight if this job runs at exactly midnight EST
    :timer.sleep(delay)
    local_date_now = Timex.now("America/New_York") |> Timex.to_date()

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

  def list_next_broker_oh_listings(nil, _number, after_datetime) do
    now = after_datetime || NaiveDateTime.utc_now()
    # so 9am inspections still show up on sheet at 1pm (but not later)
    now = now |> Timex.shift(hours: -4) |> Timex.to_naive_datetime()

    Repo.all(
      from(
        l in Listing,
        where: l.first_broker_oh_start_at > ^now and l.draft == false,
        or_where: l.second_broker_oh_start_at > ^now and l.draft == false,
        order_by: [asc: l.first_broker_oh_start_at, asc: l.second_broker_oh_start_at],
        # limit: ^number,
        preload: [:broker, :user]
      )
    )
  end

  # def list_next_broker_oh_listings(current_user, number, after_datetime) do
  #   now = after_datetime || NaiveDateTime.utc_now
  #   now = now |> Timex.shift(hours: -4) |> Timex.to_naive_datetime # so 9am inspections still show up on sheet at 1pm (but not later)
  #   Repo.all(from l in Listing, where: l.first_broker_oh_start_at > ^now and l.draft == false, or_where: l.second_broker_oh_start_at > ^now and l.draft == false, order_by: [asc: l.first_broker_oh_start_at, asc: l.second_broker_oh_start_at], limit: ^number, preload: [:broker, :user])
  # end

  def list_next_cust_oh_listings(_, _, _after_datetime \\ nil)

  def list_next_cust_oh_listings(nil, _number, after_datetime) do
    now = after_datetime || NaiveDateTime.utc_now()
    # so 9am open houses still show up on sheet at 1pm (but not later)
    now = now |> Timex.shift(hours: -4) |> Timex.to_naive_datetime()

    Repo.all(
      from(
        l in Listing,
        where: l.first_cust_oh_start_at > ^now and l.draft == false,
        or_where: l.second_cust_oh_start_at > ^now and l.draft == false,
        order_by: [asc: l.first_cust_oh_start_at, asc: l.second_cust_oh_start_at],
        # limit: ^number,
        preload: [:broker, :user]
      )
    )
  end

  defp default_search_scope(current_user) do
    # regular realtor
    if Permissions.office_admin_or_site_admin?(current_user) do
      # site admin
      if Permissions.office_admin?(current_user) do
        current_office = get_office!(current_user.office_id)

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
      default_search_scope(current_user) |> where([l], l.listing_status_type in ~w[NEW FS EXT PC])

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
    date = case Date.new(_try_integer(year), _try_integer(month), _try_integer(day)) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
    case date do
      nil -> nil
      date -> ({:ok, date} = NaiveDateTime.new(date, ~T[00:00:00]); date)
    end
  end

  @my_office_regex ~r/ ?\bmy office\b ?/i
  defp try_my_office({query, scope, errors}, current_user) do
    if Regex.match?(@my_office_regex, query) do
      current_office = get_office!(current_user.office_id)

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
    valid_startday = convert_binary_date_parts_to_naivedatetime_struct(start_yr, start_mon, start_day)
    valid_finishday = convert_binary_date_parts_to_naivedatetime_struct(finish_yr, finish_mon, finish_day)

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
    valid_startday = convert_binary_date_parts_to_naivedatetime_struct(start_yr, start_mon, start_day)
    valid_finishday = convert_binary_date_parts_to_naivedatetime_struct(finish_yr, finish_mon, finish_day)

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
    valid_startday = convert_binary_date_parts_to_naivedatetime_struct(start_yr, start_mon, start_day)
    valid_finishday = convert_binary_date_parts_to_naivedatetime_struct(finish_yr, finish_mon, finish_day)

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
    valid_startday = convert_binary_date_parts_to_naivedatetime_struct(start_yr, start_mon, start_day)
    valid_finishday = convert_binary_date_parts_to_naivedatetime_struct(finish_yr, finish_mon, finish_day)

    cond do
      valid_startday && valid_finishday ->
        {Regex.replace(regex, query, ""),
         scope |> where([l], l.expires_on >= ^valid_startday and l.expires_on <= ^valid_finishday),
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
  @listing_status_type_regex ~r/\b(NEW|FS|EXT|UC|CL|PC|WR|TOM|EXP)\b/
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
    if (
          Regex.match?(@all_regex, query) or
          Regex.match?(@active_regex, query) or
          Regex.match?(@inactive_regex, query) or
          Regex.match?(@listing_status_type_regex, query) or
          Regex.match?(@expired_regex, query) or
          Regex.match?(@daterange_fs_regex, query) or
          Regex.match?(@daterange_uc_regex, query) or
          Regex.match?(@daterange_cl_regex, query) or
          Regex.match?(@daterange_exp_regex, query)
      ) do
      # just pass it through
      {Regex.replace(@all_regex, query, ""), scope, errors}
    else
      # default to active scope
      {Regex.replace(@active_regex, query, ""),
       scope |> where([l], l.listing_status_type in ~w[NEW FS EXT PC]), errors}
    end
  end


  defp try_active_inactive({query, scope, errors}) do
    query = Regex.replace(@active_regex, query, "(NEW|FS|EXT|PC)")
    query = Regex.replace(@inactive_regex, query, "(CL|WR|TOM|EXP)")
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

  @doc """
  Gets a single listing.

  Raises `Ecto.NoResultsError` if the Listing does not exist.

  ## Examples

      iex> get_listing!(123)
      %Listing{}

      iex> get_listing!(456)
      ** (Ecto.NoResultsError)

  """
  def get_listing!(id), do: Repo.get!(Listing, id, preload: [:broker, :user])

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
    Repo.all(from(l in Listing, where: l.id in ^ids, order_by: [desc: l.updated_at]), preload: [:broker, :user])
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

  ### Undelete/soft-delete support

  @doc """
  Deletes a Listing.

  ## Examples

      iex> delete_listing(listing)
      {:ok, %Listing{}}

      iex> delete_listing(listing)
      {:error, %Ecto.Changeset{}}

  """
  def delete_listing(%Listing{} = listing) do
    case Repo.delete(listing) do
      {:ok, listing} -> {:ok, get_deleted_listing(listing.id)}
      result -> result
    end
  end

  # def delete_all_listings(query \\ Listing) do
  #   Repo.delete_all(query)
  # end

  def list_deleted_listings() do
    Repo.all(from(l in Listing, prefix: "public", where: not is_nil(l.deleted_at)))
  end

  def get_deleted_listing(id) do
    Repo.get(from(l in Listing, prefix: "public"), id)
  end

  def undelete_listing(listing) do
    listing
    |> Listing.undelete_changeset()
    |> Repo.update()
  end

  def hard_delete_listing(listing) do
    Repo.hard_delete(listing)
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
      from(
        office in Office,
        select: {office.id, office.name},
        order_by: [asc: office.name]
      )
    )
  end

  @doc """
  Returns the list of offices.

  ## Examples

      iex> list_offices()
      [%Office{}, ...]

  """
  def list_offices do
    Repo.all(from(office in Office, order_by: [asc: office.name]))
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
