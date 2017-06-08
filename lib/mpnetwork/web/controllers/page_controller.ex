defmodule Mpnetwork.Web.PageController do
  use Mpnetwork.Web, :controller

  def index(conn, _params) do
# IO.inspect conn
# IO.inspect current_user(conn)
    render conn, "index.html"
  end
end
