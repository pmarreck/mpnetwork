defmodule MpnetworkWeb.SearchControllerTest do
  use MpnetworkWeb.ConnCase, async: true

  import Mpnetwork.Test.Support.Utilities

  test "search of a blank works", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> assign(:current_user, user)
      |> get(Routes.listing_path(conn, :index, %{q: "", limit: 50}))

    assert html_response(conn, 200) =~ "No listings"
  end

  test "search of an actual attribute works", %{conn: conn} do
    user = user_fixture()
    listing = fixture(:listing, user)

    conn =
      conn
      |> assign(:current_user, user)
      |> get(Routes.listing_path(conn, :index, %{q: "FS", limit: 50}))
    assert html_response(conn, 200) =~ listing.address
  end

  test "search of coming-soon listing status works", %{conn: conn} do
    user = user_fixture()
    listing = fixture(:listing, user, %{listing_status_type: "CS", address: "#{rand_between(10000,99999)} search lane"})
    # sanity check
    :CS = listing.listing_status_type

    conn =
      conn
      |> assign(:current_user, user)
      |> get(Routes.listing_path(conn, :index, %{q: "CS", limit: 50}))
    refute html_response(conn, 200) =~ "0 total results"
    assert html_response(conn, 200) =~ listing.address
  end

  test "search of a date range on listing date works", %{conn: conn} do
    user = user_fixture()
    _listing = fixture(:listing, user)

    conn =
      conn
      |> assign(:current_user, user)
      |> get(Routes.listing_path(conn, :index, %{q: "FS: 12/1/2017-12/31/2025", limit: 1}))

    assert html_response(conn, 200) =~ "FS"
  end
end
