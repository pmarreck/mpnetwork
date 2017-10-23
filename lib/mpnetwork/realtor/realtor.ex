defmodule Mpnetwork.Realtor do
  @moduledoc """
  The boundary for the Realtor system.
  """

  import Ecto.Query, warn: false

  alias Mpnetwork.Realtor.{Broadcast, Listing, Office}
  alias Mpnetwork.{Repo, User, EnumMaps}

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
    Repo.all(from u in User, order_by: [asc: u.name]) |> Repo.preload(:broker)
  end

  def list_users(nil) do
    Repo.all(from u in User, order_by: [asc: u.name])
  end

  def list_users(office) do
    Repo.all(from u in User, where: u.office_id == ^office.id, order_by: [asc: u.name])
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

      iex> list_listings()
      [%Listing{}, ...]

  """
  def list_latest_listings(nil, limit) do
    Repo.all(from l in Listing, where: l.draft == false, order_by: [desc: l.updated_at], limit: ^limit) |> Repo.preload([:broker, :user])
  end

  @doc """
  Returns the latest listings by this user

  ## Examples

      iex> list_listings()
      [%Listing{}, ...]

  """
  def list_latest_listings(current_user, limit) do
    Repo.all(from l in Listing, where: l.user_id == ^current_user.id, order_by: [desc: l.updated_at], limit: ^limit) |> Repo.preload([:broker, :user])
  end

  def list_latest_draft_listings(current_user) when current_user != nil do
    Repo.all(from l in Listing, where: l.user_id == ^current_user.id and l.draft == true, order_by: [desc: l.updated_at], limit: 30) |> Repo.preload([:broker, :user])
  end

  @doc """
  Returns the next N listings with upcoming broker open houses.

  ## Examples

      iex> list_next_broker_oh_listings()
      [%Listing{}, ...]

  """
  def list_next_broker_oh_listings(current_user, number) do
    now = Timex.now()
    Repo.all(from l in Listing, where: l.next_broker_oh_start_at > ^now and l.draft == false or l.user_id == ^current_user.id, order_by: [desc: l.next_broker_oh_start_at], limit: ^number) |> Repo.preload([:broker, :user])
  end

  @doc """
  Queries listings.
  """
  def query_listings(query, current_user) do
    default_scope = from l in Listing, where: l.draft == false or l.user_id == ^current_user.id, order_by: [desc: l.updated_at], limit: 50
    id = _try_integer(query)
    lst = _try_listing_status_type(query)
    my  = _try_mine(query)
    pricerange = _try_pricerange(query)
    cond do
      query == ""              -> Repo.all(default_scope) |> Repo.preload([:broker, :user])
      id                       -> ((get_listings([id]) ++ search_all_fields_using_postgres_fulltext_search(query, default_scope)) |> Enum.uniq) |> Repo.preload([:broker, :user])
      lst                      -> default_scope |> where([l], l.listing_status_type == ^lst) |> Repo.all |> Repo.preload([:broker, :user])
      my                       -> default_scope |> where([l], l.user_id == ^current_user.id) |> Repo.all |> Repo.preload([:broker, :user])
      pricerange               -> {start, finish} = pricerange; default_scope |> where([l], l.price_usd >= ^start and l.price_usd <= ^finish) |> Repo.all |> Repo.preload([:broker, :user])
      true                     -> search_all_fields_using_postgres_fulltext_search(query, default_scope)
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

  defp _try_listing_status_type(maybe_lst) when is_binary(maybe_lst) do
    cond do
      Enum.member?(EnumMaps.listing_status_types_int_bin, maybe_lst) -> maybe_lst
      true -> nil
    end
  end

  defp _try_mine(maybe_my) when is_binary(maybe_my) do
    Enum.member?(["my", "mine"], String.downcase(maybe_my))
  end

  @pricerange_regex ~r/^\$?([0-9,_ ]+)-\$?([0-9,_ ]+)$/
  defp _try_pricerange(maybe_pr) when is_binary(maybe_pr) do
    case Regex.run(@pricerange_regex, maybe_pr) do
      [_, start, finish] -> {_filter_nonnumeric(start), _filter_nonnumeric(finish)}
      _ -> nil
    end
  end

  defp _filter_nonnumeric(num) when is_binary(num) do
    {num, _} = Integer.parse(Regex.replace(~r/[^0-9]+/, num, ""))
    num
  end

  defp normalization_transformations() do
    [
      {~r/\s*\<([0-9]+|-)\>\s*/, "<\\1>"},
      {~r/"\s*([^"]+?)\s*"/, fn _, phrase -> Regex.replace(~r/ +/, phrase, "<->") end},
      {~r/\s+and\s+/i, "&"},
      {~r/\s+or\s+/i, "|"},
      {~r/\s+or\s+/i, "|"},
      {~r/\s*&not\b/i, "&!"},
      {~r/\s*\|not\b/i, "|!"},
      {~r/\bnot\s+/i, "!"},
      {~r/\s*&\s*/, "&"},
      {~r/\s*\|\s*/, "|"},
      {~r/!\s+/, "!"},
      {~r/\s+/, "&"},
    ]
  end

  defp normalize_query(q) do
    Enum.reduce(normalization_transformations(), String.trim(q), fn({regex, repl}, acc) -> Regex.replace(regex, acc, repl) end)
  end

  def test_normalize_query() do
    test_cases = [
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
    ]
    for {expected, input} <- test_cases, do: ^expected = normalize_query(input)
    true
  end


  defp search_all_fields_using_postgres_fulltext_search(q, scope) do
    q = normalize_query(q)
    scope
    |> where([l], fragment("search_vector @@ to_tsquery(?)", ^q))
    |> order_by([l], [asc: fragment("ts_rank_cd(search_vector, to_tsquery(?), 32)", ^q), desc: l.updated_at])
    |> Repo.all
    |> Repo.preload([:broker, :user])
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
      order_by: [desc: office.name]
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
      order_by: [desc: office.name]
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
