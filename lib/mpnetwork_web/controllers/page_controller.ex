defmodule MpnetworkWeb.PageController do
  use MpnetworkWeb, :controller

  alias Mpnetwork.{Realtor, Listing, Permissions}

  # Primary landing page view
  def index(conn, _params) do
    u = conn.assigns.current_user
    broadcasts = Realtor.list_latest_broadcasts(4) |> Enum.reverse
    newest_listings = Realtor.list_most_recently_created_listings(nil, 15)
    draft_listings = if !Permissions.read_only?(u) do
      if Permissions.office_admin_or_site_admin?(u) do
        Realtor.list_latest_draft_listings(conn.assigns.current_office)
      else
        Realtor.list_latest_draft_listings(u)
      end
    else
      nil
    end
    newest_primaries = Listing.primary_images_for_listings(newest_listings)
    draft_primaries = if draft_listings do
      Listing.primary_images_for_listings(draft_listings)
    else
      nil
    end
    render(conn, "index.html",
      broadcasts: broadcasts,
      newest_listings: newest_listings,
      newest_primaries: newest_primaries,
      draft_listings: draft_listings,
      draft_primaries: draft_primaries
    )
  end

  def bare_session_redirect(conn, _params) do
    redirect(conn, to: page_path(conn, :index))
  end

end
