defmodule Mpnetwork.Web.ListingController do
  use Mpnetwork.Web, :controller

  alias Mpnetwork.Realtor

  def index(conn, _params) do
    listings = Realtor.list_listings()
    render(conn, "index.html", listings: listings)
  end

  def new(conn, _params) do
    changeset = Realtor.change_listing(%Mpnetwork.Realtor.Listing{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"listing" => listing_params}) do
    case Realtor.create_listing(listing_params) do
      {:ok, listing} ->
        conn
        |> put_flash(:info, "Listing created successfully.")
        |> redirect(to: listing_path(conn, :show, listing))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    render(conn, "show.html", listing: listing)
  end

  def edit(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    changeset = Realtor.change_listing(listing)
    render(conn, "edit.html", listing: listing, changeset: changeset)
  end

  def update(conn, %{"id" => id, "listing" => listing_params}) do
    listing = Realtor.get_listing!(id)

    case Realtor.update_listing(listing, listing_params) do
      {:ok, listing} ->
        conn
        |> put_flash(:info, "Listing updated successfully.")
        |> redirect(to: listing_path(conn, :show, listing))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", listing: listing, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    {:ok, _listing} = Realtor.delete_listing(listing)

    conn
    |> put_flash(:info, "Listing deleted successfully.")
    |> redirect(to: listing_path(conn, :index))
  end
end
