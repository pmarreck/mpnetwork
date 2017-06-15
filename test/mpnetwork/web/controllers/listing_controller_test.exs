defmodule Mpnetwork.Web.ListingControllerTest do
  use Mpnetwork.Web.ConnCase

  alias Mpnetwork.Realtor

  @create_attrs %{expires_on: ~D[2010-04-17], state: "some state", new_construction: true, fios_available: true, tax_rate_code_area: 42, total_annual_property_taxes_usd: 42, num_skylights: 42, lot_size_acre_cents: 42, attached_garage: true, for_rent: true, zip: "some zip", ext_url: "some ext_url", visible_on: ~D[2010-04-17], city: "some city", fireplaces: 42, new_appliances: true, modern_kitchen_countertops: true, deck: true, for_sale: true, central_air: true, stories: 42, num_half_baths: 42, year_built: 42, draft: true, pool: true, mls_source_id: 42, security_system: true, sq_ft: 42, studio: true, cellular_coverage_quality: 42, hot_tub: true, basement: true, price_usd: 42, special_notes: "some special_notes", parking_spaces: 42, description: "some description", num_bedrooms: 42, high_speed_internet_available: true, patio: true, address: "some address", num_garages: 42, num_baths: 42, central_vac: true, led_lighting: true}
  @update_attrs %{expires_on: ~D[2011-05-18], state: "some updated state", new_construction: false, fios_available: false, tax_rate_code_area: 43, total_annual_property_taxes_usd: 43, num_skylights: 43, lot_size_acre_cents: 43, attached_garage: false, for_rent: false, zip: "some updated zip", ext_url: "some updated ext_url", visible_on: ~D[2011-05-18], city: "some updated city", fireplaces: 43, new_appliances: false, modern_kitchen_countertops: false, deck: false, for_sale: false, central_air: false, stories: 43, num_half_baths: 43, year_built: 43, draft: false, pool: false, mls_source_id: 43, security_system: false, sq_ft: 43, studio: false, cellular_coverage_quality: 43, hot_tub: false, basement: false, price_usd: 43, special_notes: "some updated special_notes", parking_spaces: 43, description: "some updated description", num_bedrooms: 43, high_speed_internet_available: false, patio: false, address: "some updated address", num_garages: 43, num_baths: 43, central_vac: false, led_lighting: false}
  @invalid_attrs %{expires_on: nil, state: nil, new_construction: nil, fios_available: nil, tax_rate_code_area: nil, total_annual_property_taxes_usd: nil, num_skylights: nil, lot_size_acre_cents: nil, attached_garage: nil, for_rent: nil, zip: nil, ext_url: nil, visible_on: nil, city: nil, fireplaces: nil, new_appliances: nil, modern_kitchen_countertops: nil, deck: nil, for_sale: nil, central_air: nil, stories: nil, num_half_baths: nil, year_built: nil, draft: nil, pool: nil, mls_source_id: nil, security_system: nil, sq_ft: nil, studio: nil, cellular_coverage_quality: nil, hot_tub: nil, basement: nil, price_usd: nil, special_notes: nil, parking_spaces: nil, description: nil, num_bedrooms: nil, high_speed_internet_available: nil, patio: nil, address: nil, num_garages: nil, num_baths: nil, central_vac: nil, led_lighting: nil}

  @valid_user_attrs %{email: "test@example.com", password: "unit test all the things!", password_confirmation: "unit test all the things!"}

  def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_user_attrs)
        |> Realtor.create_user()
      user
  end

  def fixture(:listing) do
    user = user_fixture()
    {:ok, listing} = Realtor.create_listing(Enum.into(%{user_id: user.id}, @create_attrs))
    listing
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, listing_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Listings"
  end

  test "renders form for new listings", %{conn: conn} do
    conn = get conn, listing_path(conn, :new)
    assert html_response(conn, 200) =~ "New Listing"
  end

  test "creates listing and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, listing_path(conn, :create), listing: @create_attrs

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == listing_path(conn, :show, id)

    conn = get conn, listing_path(conn, :show, id)
    assert html_response(conn, 200) =~ "Show Listing"
  end

  test "does not create listing and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, listing_path(conn, :create), listing: @invalid_attrs
    assert html_response(conn, 200) =~ "New Listing"
  end

  test "renders form for editing chosen listing", %{conn: conn} do
    listing = fixture(:listing)
    conn = get conn, listing_path(conn, :edit, listing)
    assert html_response(conn, 200) =~ "Edit Listing"
  end

  test "updates chosen listing and redirects when data is valid", %{conn: conn} do
    listing = fixture(:listing)
    conn = put conn, listing_path(conn, :update, listing), listing: @update_attrs
    assert redirected_to(conn) == listing_path(conn, :show, listing)

    conn = get conn, listing_path(conn, :show, listing)
    assert html_response(conn, 200) =~ "some updated state"
  end

  test "does not update chosen listing and renders errors when data is invalid", %{conn: conn} do
    listing = fixture(:listing)
    conn = put conn, listing_path(conn, :update, listing), listing: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Listing"
  end

  test "deletes chosen listing", %{conn: conn} do
    listing = fixture(:listing)
    conn = delete conn, listing_path(conn, :delete, listing)
    assert redirected_to(conn) == listing_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, listing_path(conn, :show, listing)
    end
  end
end
