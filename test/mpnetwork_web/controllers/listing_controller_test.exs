defmodule MpnetworkWeb.ListingControllerTest do

  # use ExUnit.Case, async: true

  use MpnetworkWeb.ConnCase, async: true

  alias Mpnetwork.{Realtor, Repo}
  alias Mpnetwork.Realtor.Listing
  # import Mpnetwork.Test.Support.Utilities

  @create_attrs %{expires_on: ~D[2010-04-17], state: "some state", new_construction: true, fios_available: true, tax_rate_code_area: 42, prop_tax_usd: 42, num_skylights: 42, lot_size: "420x240", attached_garage: true, for_rent: true, zip: "11050", ext_urls: ["some ext_urls"], visible_on: ~D[2010-04-17], city: "some city", num_fireplaces: 2, modern_kitchen_countertops: true, deck: true, for_sale: true, central_air: true, stories: 42, num_half_baths: 42, year_built: 42, draft: true, pool: true, mls_source_id: 42, security_system: true, sq_ft: 42, studio: true, cellular_coverage_quality: 3, hot_tub: true, basement: true, price_usd: 42, remarks: "some remarks", parking_spaces: 42, description: "some description", num_bedrooms: 42, high_speed_internet_available: true, patio: true, address: "some address", num_garages: 42, num_baths: 42, central_vac: true, eef_led_lighting: true}
  @update_attrs %{expires_on: ~D[2011-05-18], state: "some updated state", new_construction: false, fios_available: false, tax_rate_code_area: 43, prop_tax_usd: 43, num_skylights: 43, lot_size: "430x720", attached_garage: false, for_rent: false, zip: "some updated zip", ext_urls: ["some updated ext_urls"], visible_on: ~D[2011-05-18], city: "some updated city", num_fireplaces: 43, modern_kitchen_countertops: false, deck: false, for_sale: false, central_air: false, stories: 43, num_half_baths: 43, year_built: 43, draft: true, pool: false, mls_source_id: 43, security_system: false, sq_ft: 43, studio: false, cellular_coverage_quality: 4, hot_tub: false, basement: false, price_usd: 43, remarks: "some updated remarks", parking_spaces: 43, description: "some updated description", num_bedrooms: 43, high_speed_internet_available: false, patio: false, address: "some updated address", num_garages: 43, num_baths: 43, central_vac: false, eef_led_lighting: false}
  @invalid_attrs %{expires_on: nil, state: nil, new_construction: nil, fios_available: nil, tax_rate_code_area: nil, prop_tax_usd: nil, num_skylights: nil, lot_size: nil, attached_garage: nil, for_rent: nil, zip: nil, ext_urls: nil, visible_on: nil, city: nil, num_fireplaces: nil, modern_kitchen_countertops: nil, deck: nil, for_sale: nil, central_air: nil, stories: nil, num_half_baths: nil, year_built: nil, draft: false, pool: nil, mls_source_id: nil, security_system: nil, sq_ft: nil, studio: nil, cellular_coverage_quality: 10, hot_tub: nil, basement: nil, price_usd: nil, remarks: nil, parking_spaces: nil, description: nil, num_bedrooms: nil, high_speed_internet_available: nil, patio: nil, address: nil, num_garages: nil, num_baths: nil, central_vac: nil, eef_led_lighting: nil}

  def valid_user_attrs, do: %{email: "test@example#{:rand.uniform(9999999999999)}.com", username: "testuser#{:rand.uniform(9999999999999)}", password: "unit test all the things!", password_confirmation: "unit test all the things!", role_id: 2}

  setup %{conn: conn} do
    office = office_fixture()
    user = user_fixture(%{office: office, office_id: office.id})
    conn = assign(conn, :current_office, office)
    {:ok, conn: assign(conn, :current_user, user), user: user}
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(valid_user_attrs())
      |> Realtor.create_user()
    user
  end

  @valid_office_attrs %{name: "Coach"}
  def office_fixture(attrs \\ %{}) do
    {:ok, office} =
      attrs
      |> Enum.into(@valid_office_attrs)
      |> Realtor.create_office()
    office
  end

  def fixture(:listing, user \\ user_fixture()) do
    office = office_fixture()
    {:ok, listing} = Realtor.create_listing(Enum.into(%{user_id: user.id, user: user, broker_id: office.id, broker: office}, @create_attrs))
    listing
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, listing_path(conn, :index)
    assert html_response(conn, 200) =~ ~r/Latest [0-9]+ listings/
  end

  test "renders form for new listings", %{conn: conn} do
    conn = get conn, listing_path(conn, :new)
    assert html_response(conn, 200) =~ "Attachments can be added after saving the listing"
  end

  test "creates listing and redirects to show when data is valid", %{conn: original_conn} do
    conn = original_conn
    conn = post conn, listing_path(conn, :create), listing: @create_attrs
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == listing_path(conn, :show, id)
    conn = original_conn
    conn = get conn, listing_path(conn, :show, id)
    assert html_response(conn, 200) =~ "some city"
  end

  test "does not create listing and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, listing_path(conn, :create), listing: @invalid_attrs
    assert html_response(conn, 200) =~ "is invalid"
  end

  test "renders form for editing chosen listing", %{conn: conn} do
    listing = fixture(:listing, conn.assigns.current_user)
    conn = get conn, listing_path(conn, :edit, listing)
    assert html_response(conn, 200) =~ "listing[for_sale]"
  end

  test "updates chosen listing and redirects when data is valid", %{conn: initial_conn} do
    conn = initial_conn
    listing = fixture(:listing, conn.assigns.current_user)
    conn = put conn, listing_path(conn, :update, listing), listing: @update_attrs
    assert Repo.get(Listing, listing.id)
    assert redirected_to(conn) == listing_path(conn, :show, listing)

    conn = get initial_conn, listing_path(initial_conn, :show, listing)
    assert html_response(conn, 200) =~ "some updated state"
  end

  test "does not update chosen listing and renders errors when data is invalid", %{conn: conn} do
    listing = fixture(:listing, conn.assigns.current_user)
    conn = put conn, listing_path(conn, :update, listing), listing: @invalid_attrs
    assert html_response(conn, 200) =~ "Oops"
  end

  test "deletes chosen listing", %{conn: initial_conn} do
    conn = initial_conn
    listing = fixture(:listing, conn.assigns.current_user)
    conn = delete conn, listing_path(conn, :delete, listing)
    assert redirected_to(conn) == listing_path(conn, :index)
    assert_error_sent 404, fn ->
      get initial_conn, listing_path(initial_conn, :show, listing)
    end
  end
end
