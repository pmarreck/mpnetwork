defmodule MpnetworkWeb.ListingController do
  use MpnetworkWeb, :controller

  require Logger

  alias Mpnetwork.{Realtor, Listing, ClientEmail, Repo, Mailer}
  # alias Mpnetwork.Realtor.Office

  import Listing, only: [public_client_listing_code: 1, public_agent_listing_code: 1]

  plug :put_layout, "public_listing.html" when action in [:client_listing, :agent_listing]

  def index(conn, _params) do
    listings = Realtor.list_latest_listings(nil, 30)
    primaries = Listing.primary_images_for_listings(listings)
    draft_listings = Realtor.list_latest_draft_listings(conn.assigns.current_user)
    draft_primaries = Listing.primary_images_for_listings(draft_listings)
    render(conn, "index.html",
      listings: listings,
      primaries: primaries,
      draft_listings: draft_listings,
      draft_primaries: draft_primaries
    )
  end

  def new(conn, _params) do
    changeset = Realtor.change_listing(%Mpnetwork.Realtor.Listing{
      user_id: current_user(conn).id,
      broker_id: conn.assigns.current_office.id
    })
    render(conn, "new.html",
      changeset: changeset,
      offices: offices(),
      users: users(conn.assigns.current_office)
    )
  end

  def create(conn, %{"listing" => listing_params}) do
    # inject current_user.id and current_office.id (as broker_id)
    listing_params = Enum.into(%{"user_id" => current_user(conn).id, "broker_id" => conn.assigns.current_office.id}, listing_params)
    listing_params = filter_empty_ext_urls(listing_params)
    case Realtor.create_listing(listing_params) do
      {:ok, listing} ->
        conn
        |> put_flash(:info, "Listing created successfully.")
        |> redirect(to: listing_path(conn, :show, listing))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html",
          changeset: changeset,
          offices: offices(),
          users: users(conn.assigns.current_office)
        )
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
      ensure_owner_or_admin(conn, listing, fn ->
        attachments = Listing.list_attachments(listing.id)
        changeset = Realtor.change_listing(listing)
        render(conn, "edit.html",
          listing: listing,
          attachments: attachments,
          changeset: changeset,
          broker: listing.broker,
          offices: offices(),
          users: users(conn.assigns.current_office)
        )
      end)
    end
  end

  def edit_mls(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    ensure_owner_or_admin(conn, listing, fn ->
      attachments = Listing.list_attachments(listing.id)
      changeset = Realtor.change_listing(listing)
      render(conn, "edit_mls.html",
        listing: listing,
        attachments: attachments,
        changeset: changeset,
        offices: offices(),
        users: users(conn.assigns.current_office)
      )
    end)
  end

  def update(conn, %{"id" => id, "listing" => listing_params}) do
# IO.inspect listing_params, limit: :infinity
    listing = Realtor.get_listing!(id)
    listing_params = filter_empty_ext_urls(listing_params)
    ensure_owner_or_admin(conn, listing, fn ->
      case Realtor.update_listing(listing, listing_params) do
        {:ok, listing} ->
          conn
          |> put_flash(:info, "Listing updated successfully.")
          |> redirect(to: listing_path(conn, :show, listing))
        {:error, %Ecto.Changeset{} = changeset} ->
          attachments = Listing.list_attachments(id)
          render(conn, "edit.html",
            listing: listing,
            attachments: attachments,
            changeset: changeset,
            offices: offices(),
            users: users(conn.assigns.current_office)
          )
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    ensure_owner_or_admin(conn, listing, fn ->
      {:ok, _listing} = Realtor.delete_listing(listing)

      conn
      |> put_flash(:info, "Listing deleted successfully.")
      |> redirect(to: listing_path(conn, :index))
    end)
  end

  def client_listing(conn, %{"id" => id, "sig" => signature}) do
    # conn = put_layout(conn, "public_listing.html")
    listing = Realtor.get_listing!(id)
    id = listing.id
    %{^id => showcase_image} = Listing.primary_images_for_listings([listing])
    computed_sig = public_client_listing_code(listing)
    if computed_sig == signature do
      render(conn, "client_listing.html", listing: listing, showcase_image: showcase_image)
    else
      # 410 is "Gone"
      send_resp(conn, 410, "Original listing may have changed, please request a new link from the sender")
    end
  end

  def agent_listing(conn, %{"id" => id, "sig" => signature}) do
    # conn = put_layout(conn, "public_listing.html")
    listing = Realtor.get_listing!(id)
    id = listing.id
    %{^id => showcase_image} = Listing.primary_images_for_listings([listing])
    computed_sig = public_agent_listing_code(listing)
    if computed_sig == signature do
      render(conn, "agent_listing.html", listing: listing, showcase_image: showcase_image)
    else
      send_resp(conn, 410, "Original listing may have changed, please request a new link from the listing agent")
    end
  end

  def email_listing(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    # if current_user(conn).id == listing.user_id || current_user(conn).role_id < 3 do
      render(conn, "email_listing.html", listing: listing)
    # else
    #   send_resp(conn, 405, "Not allowed to email a listing that is not yours")
    # end
  end

  def send_email(conn, %{"id" => id, "email" => %{"email_address" => email_address, "type" => type, "name" => name}} = _params) when type in ["client", "agent"] do
    listing = Realtor.get_listing!(id) |> Repo.preload(:user)
    id = listing.id
    # if current_user(conn).id == listing.user_id || current_user(conn).role_id < 3 do
      # name = if params["name"] && params["name"] != "", do: params["name"], else: nil
      # send email here with link to public MLS sheet
      url = public_client_listing_url(conn, :client_listing, id, public_client_listing_code(listing))
      # url = "/"
      {:ok, results} = ClientEmail.send_client(email_address, name, listing, url)
      |> Mailer.deliver
      Logger.info "Sent listing id #{id} of type #{type} to #{email_address}, result: #{inspect results}"
      conn
        |> put_flash(:info, "Listing emailed to #{type} at #{email_address} successfully.")
        |> redirect(to: listing_path(conn, :show, id))
    # else
    #   send_resp(conn, 405, "Not allowed to email a listing that is not yours")
    # end
  end

  defp offices do
    Realtor.list_offices
  end

  # defp users do
  #   Realtor.list_users
  # end

  defp users(office) do
    Realtor.list_users(office)
  end

  defp ensure_owner_or_admin(conn, resource, lambda) do
    u = current_user(conn)
    oid = resource.user_id
    admin = u.role_id < 3
    if u.id == oid || admin do
      lambda.()
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  defp filter_empty_ext_urls(listing_params) do
    %{"ext_urls" => ext_urls} = listing_params
    if ext_urls do
      ext_urls = Enum.filter(ext_urls, &(&1!=""))
      Enum.into(%{"ext_urls" => ext_urls}, listing_params)
    else
      listing_params
    end
  end

end
