defmodule Mpnetwork.Realtor do
  @moduledoc """
  The boundary for the Realtor system.
  """

  import Ecto.Query, warn: false
  alias Mpnetwork.Repo

  alias Mpnetwork.Realtor.Broadcast

  @doc """
  Returns the list of broadcasts.

  ## Examples

      iex> list_broadcasts()
      [%Broadcast{}, ...]

  """
  def list_broadcasts do
    Repo.all(Broadcast)
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
  def get_broadcast!(id), do: Repo.get!(Broadcast, id)

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
  def list_listings do
    Repo.all(Listing)
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
  def get_listing!(id), do: Repo.get!(Listing, id)

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
end