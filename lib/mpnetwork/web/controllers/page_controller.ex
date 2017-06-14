defmodule Mpnetwork.Web.PageController do
  use Mpnetwork.Web, :controller

  alias Mpnetwork.Realtor

  def index(conn, _params) do
# IO.inspect conn
# IO.inspect current_user(conn)
    broadcasts = Realtor.list_latest_broadcasts(4)
    listings = Realtor.list_latest_listings(conn.assigns.current_user)
    render(conn, "index.html", broadcasts: broadcasts, listings: listings)
  end
end
