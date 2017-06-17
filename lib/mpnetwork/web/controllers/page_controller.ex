defmodule Mpnetwork.Web.PageController do
  use Mpnetwork.Web, :controller

  alias Mpnetwork.{Realtor, Listing}

  def index(conn, _params) do
    broadcasts = Realtor.list_latest_broadcasts(4) |> Enum.reverse
    listings = Realtor.list_latest_listings(conn.assigns.current_user)
    primary_images = Listing.primary_images_for_listings(listings)
    render(conn, "index.html", broadcasts: broadcasts, listings: listings, primaries: primary_images)
  end
end
