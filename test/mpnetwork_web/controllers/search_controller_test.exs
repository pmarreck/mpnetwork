defmodule MpnetworkWeb.SearchControllerTest do
  use MpnetworkWeb.ConnCase, async: true

  import Mpnetwork.Test.Support.Utilities

  test "search of a blank works", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> assign(:current_user, user)
      |> get(listing_path(conn, :index, %{q: "", limit: 50}))

    assert html_response(conn, 200) =~ "No listings"
  end

  test "search of an actual attribute works", %{conn: conn} do
    user = user_fixture()
    _listing = fixture(:listing, user)

    conn =
      conn
      |> assign(:current_user, user)
      |> get(listing_path(conn, :index, %{q: "FS", limit: 50}))

    assert html_response(conn, 200) =~ "FS"
  end
end
