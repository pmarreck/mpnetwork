defmodule Mpnetwork.Realtor do
  @moduledoc """
  The boundary for the Realtor system.
  """

  import Ecto.Query, warn: false
  alias Ecto.{Multi, Changeset}

  alias Mpnetwork.Realtor.{Broadcast, Listing, Office}
  alias Mpnetwork.{Repo, User}
  alias Mpnetwork.Workers.NewListingEmailer

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
        where: not is_nil(u.locked_at) and u.failed_attempts > 0,
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
        where: not is_nil(u.locked_at) and u.failed_attempts > 0,
        order_by: [asc: u.name]
      )
    )
  end

  def get_users_who_prefer_new_listing_emails() do
    Repo.all(
      from(
        u in User,
        where: u.pref_new_listing_email == true
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
        where: l.draft == false and
          ((l.live_at >= ^day_to_filter_after and l.live_at <= ^today) or l.listing_status_type == "CS"),
        order_by: [desc: l.live_at, desc: l.updated_at],
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

  # Updates CS listings with omd_on in the local timezone past to be listing_status_type "TOM"
  def set_cs_listings_to_tom(delay \\ 1000) do
    # Just to make sure it's definitely after midnight if this job runs at exactly midnight EST
    :timer.sleep(delay)
    local_date_now = Timex.now("America/New_York") |> Timex.to_date()
    # yesterday = Timex.shift(local_date_now, days: -1)

    from(
      l in Listing,
      where: l.omd_on < ^local_date_now,
      where: l.listing_status_type in ~w[CS],
      update: [set: [listing_status_type: "TOM"]]
    )
    |> Repo.update_all([])

    # NOTE: Does NOT update updated_at (which is good in this case)
    # but DOES update the search index via trigger (which is also good in this case)
  end

  # Gets all listings in status CS (Coming Soon) that have an On Market Date (OMD) of today
  # so the owners can be notified that they need to move to NEW or FS by midnight tonight
  def get_cs_listings_with_omd_on_today() do
    local_date_now = Timex.now("America/New_York") |> Timex.to_date()
    Repo.all(
      from(
        l in Listing,
        where: l.omd_on == ^local_date_now,
        where: l.listing_status_type in ~w[CS],
        preload: [:user]
      )
    )
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
    Repo.all(from(l in Listing, where: l.id in ^ids, order_by: [desc: l.updated_at]),
      preload: [:broker, :user]
    )
  end

  # takes a Multi and a Listing and returns a Multi
  defp add_jobs_to_email_each_user_preferring_notification(%Multi{} = orig_multi, %Listing{} = listing) do
    get_users_who_prefer_new_listing_emails()
    |> Enum.reduce(orig_multi, fn user, multi ->
      job_args = %{listing_id: listing.id, user_id: user.id}
      multi
      |> Oban.insert("notify_#{user.id}_new_listing_#{listing.id}", NewListingEmailer.new(job_args))
    end)
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
    changeset = %Listing{}
    |> Listing.changeset(attrs)

    is_draft_listing = Changeset.get_field(changeset, :draft)
    lst = Changeset.get_field(changeset, :listing_status_type)
    is_cs_listing = (lst == :CS)
    is_new_listing = (lst in [:NEW, :FS])
    is_notifiable = !is_draft_listing and (is_cs_listing or is_new_listing)

    if is_notifiable do # multi a notification with the insert
      result = Multi.new()
      |> Multi.insert(:listing, changeset)
      |> Multi.merge(fn %{listing: listing} ->
        Multi.new()
        |> add_jobs_to_email_each_user_preferring_notification(listing)
      end)
      |> Repo.transaction()
      case result do
        {status, :listing, changeset, _} -> {status, changeset}
        {:ok, %{listing: listing}}       -> {:ok, listing}
      end
    else # it's either a draft or a non-new listing status; handle extended?
      Repo.insert(changeset)
    end
  end

  @doc """
  Updates a listing. Notifies on status change to NEW, FS or CS.

  ## Examples

      iex> update_listing(listing, %{field: new_value})
      {:ok, %Listing{}}

      iex> update_listing(listing, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_listing(%Listing{} = listing, attrs) do
    changeset = listing
    |> Listing.changeset(attrs)

    # alright we want to not track ALL draft listings
    # but only those coming OUT of draft.
    # Note that you do need the false comparison due to Changeset.get_change
    # possibly returning nil.
    is_newly_not_draft = (Changeset.get_change(changeset, :draft) == false)
    wasnt_draft_and_wont_change = (listing.draft == false) and (Changeset.get_change(changeset, :draft) == nil)
    # So we only want to notify when it CHANGES out of draft and IS one of the following statuses,
    # or WASN'T draft and BECOMES one of the following statuses, but not every time
    # the listing is merely updated:
    new_lst = Changeset.get_change(changeset, :listing_status_type)
    is_new_lst = new_lst != nil
    is_lst_changed_to_cs = is_new_lst and (new_lst == :CS)
    is_lst_changed_to_new = is_new_lst and (new_lst in [:NEW, :FS])
    is_lst_cs = (Changeset.get_field(changeset, :listing_status_type) == :CS)
    is_lst_new = (Changeset.get_field(changeset, :listing_status_type) in [:NEW, :FS])
    is_notifiable = (is_newly_not_draft and (is_lst_cs or is_lst_new)) or
      (wasnt_draft_and_wont_change and (is_lst_changed_to_cs or is_lst_changed_to_new))
    # whew...
    if is_notifiable do
      result = Multi.new()
      |> Multi.update(:listing, changeset)
      |> add_jobs_to_email_each_user_preferring_notification(listing)
      |> Repo.transaction()
      case result do
        {status, :listing, changeset, _} -> {status, changeset}
        {:ok, %{listing: listing}}       -> {:ok, listing}
      end
    else
      Repo.update(changeset)
    end
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
