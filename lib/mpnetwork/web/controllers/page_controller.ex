defmodule Mpnetwork.Web.PageController do
  use Mpnetwork.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
