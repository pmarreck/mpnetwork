defmodule MpnetworkWeb.PageController do
  use MpnetworkWeb, :controller

  alias Mpnetwork.{Realtor, Listing}

  def index(conn, _params) do
    u = conn.assigns.current_user
    broadcasts = Realtor.list_latest_broadcasts(4) |> Enum.reverse
    listings = Realtor.list_latest_listings(u)
    draft_listings = Realtor.list_latest_draft_listings(u)
    primary_images = Listing.primary_images_for_listings(listings)
    draft_primaries = Listing.primary_images_for_listings(draft_listings)
    render(conn, "index.html",
      broadcasts: broadcasts,
      listings: listings,
      primaries: primary_images,
      draft_listings: draft_listings,
      draft_primaries: draft_primaries
    )
  end
end
