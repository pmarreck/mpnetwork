defmodule MpnetworkWeb.LoginWorkflowTest do
  use MpnetworkWeb.ConnCase, async: true

  import Mpnetwork.Test.Support.Utilities

  # alias Mpnetwork.Realtor

  test "POST / with login and password and Remember checked works", %{conn: conn} do
    user = user_fixture(%{password: "test", password_confirmation: "test"})

    conn =
      conn
      |> post("/sessions", %{session: %{email: user.email, password: "test"}, remember: true})

    # assert redirected to root
    assert html_response(conn, 302) =~ "<a href=\"/\">redirected</a>"

    conn =
      conn
      |> get("/")

    assert html_response(conn, 200) =~ "No listings"
  end

end
