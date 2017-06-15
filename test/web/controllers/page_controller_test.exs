defmodule Mpnetwork.Web.PageControllerTest do
  use Mpnetwork.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Please log in"
  end
end
