defmodule Mpnetwork.Web.ListingController do
  use Mpnetwork.Web, :controller

  alias Mpnetwork.{Realtor, Listing}

  def index(conn, _params) do
    listings = Realtor.list_listings(current_user(conn))
    primaries = Listing.primary_images_for_listings(listings)
    render(conn, "index.html", listings: listings, primaries: primaries)
  end

  def new(conn, _params) do
    changeset = Realtor.change_listing(%Mpnetwork.Realtor.Listing{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"listing" => listing_params}) do
    # inject current_user.id
    listing_params_with_current_user_id = Enum.into(%{"user_id" => current_user(conn).id}, listing_params)

    case Realtor.create_listing(listing_params_with_current_user_id) do
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
    attachments = Listing.list_attachments(id)
    render(conn, "show.html", listing: listing, attachments: attachments)
  end

  def edit(conn, %{"id" => id} = params) do
    if params["version"] == "mls" do
      edit_mls(conn, params)
    else
      listing = Realtor.get_listing!(id)
      if current_user(conn).id == listing.user_id || current_user(conn).role_id < 3 do
        attachments = Listing.list_attachments(listing.id)
        changeset = Realtor.change_listing(listing)
        render(conn, "edit.html", listing: listing, attachments: attachments, changeset: changeset)
      else
        render(conn, 405, "Not allowed")
      end
    end
  end

  def edit_mls(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    if current_user(conn).id == listing.user_id || current_user(conn).role_id < 3 do
      attachments = Listing.list_attachments(listing.id)
      changeset = Realtor.change_listing(listing)
      render(conn, "edit_mls.html", listing: listing, attachments: attachments, changeset: changeset)
    else
      render(conn, 405, "Not allowed")
    end
  end

  def update(conn, %{"id" => id, "listing" => listing_params}) do
    listing = Realtor.get_listing!(id)
    if current_user(conn).id == listing.user_id || current_user(conn).role_id < 3 do
      case Realtor.update_listing(listing, listing_params) do
        {:ok, listing} ->
          conn
          |> put_flash(:info, "Listing updated successfully.")
          |> redirect(to: listing_path(conn, :show, listing))
        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", listing: listing, changeset: changeset)
      end
    else
      render(conn, 405, "Not allowed")
    end
  end

  def delete(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    if current_user(conn).id == listing.user_id || current_user(conn).role_id < 3 do
      {:ok, _listing} = Realtor.delete_listing(listing)

      conn
      |> put_flash(:info, "Listing deleted successfully.")
      |> redirect(to: listing_path(conn, :index))
    else
      render(conn, 405, "Not allowed")
    end
  end
end
