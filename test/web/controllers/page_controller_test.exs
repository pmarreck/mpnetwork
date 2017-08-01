defmodule MpnetworkWeb.PageControllerTest do
  use MpnetworkWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Please log in"
  end
end
