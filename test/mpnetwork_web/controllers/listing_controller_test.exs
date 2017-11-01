defmodule MpnetworkWeb.ListingControllerTest do

  # use ExUnit.Case, async: true

  use MpnetworkWeb.ConnCase, async: true

  import Mpnetwork.Test.Support.Utilities

  alias Mpnetwork.{Realtor, Repo}
  alias Mpnetwork.Realtor.Listing
  # import Mpnetwork.Test.Support.Utilities
  import Mpnetwork.Listing, only: [public_client_listing_code: 1, public_client_listing_code: 2, now_in_unix_epoch_days: 0]

  @create_attrs %{schools: "Port", prop_tax_usd: "1000", vill_tax_usd: "1000", section_num: "1", block_num: "1", lot_num: "A", visible_on: ~D[2017-11-17], expires_on: ~D[2018-04-17], state: "some state", new_construction: true, fios_available: true, tax_rate_code_area: 42, num_skylights: 42, lot_size: "420x240", attached_garage: true, for_rent: true, zip: "11050", ext_urls: ["http://www.yahoo.com"], city: "some city", num_fireplaces: 2, modern_kitchen_countertops: true, deck: true, for_sale: true, central_air: true, stories: 42, num_half_baths: 42, year_built: 1984, draft: true, pool: true, mls_source_id: 42, security_system: true, sq_ft: 42, studio: true, cellular_coverage_quality: 3, hot_tub: true, basement: true, price_usd: 42, realtor_remarks: "some remarks", parking_spaces: 42, description: "some description", num_bedrooms: 42, high_speed_internet_available: true, patio: true, address: "some address", num_garages: 42, num_baths: 42, central_vac: true, eef_led_lighting: true}
  @create_upcoming_broker_oh_attrs Enum.into(%{next_broker_oh_start_at: Timex.shift(Timex.now(), hours: 2), address: "inspectionaddress", draft: false}, @create_attrs)
  @update_attrs %{schools: "Man", prop_tax_usd: "100", vill_tax_usd: "100", section_num: "A", block_num: "2", lot_num: "B", visible_on: ~D[2011-04-18], expires_on: ~D[2011-05-18], state: "some updated state", new_construction: false, fios_available: false, tax_rate_code_area: 43, num_skylights: 43, lot_size: "430x720", attached_garage: false, for_rent: false, zip: "some updated zip", ext_urls: ["http://www.google.com"], city: "some updated city", num_fireplaces: 43, modern_kitchen_countertops: false, deck: false, for_sale: false, central_air: false, stories: 43, num_half_baths: 43, year_built: 1990, draft: true, pool: false, mls_source_id: 43, security_system: false, sq_ft: 43, studio: false, cellular_coverage_quality: 4, hot_tub: false, basement: false, price_usd: 43, realtor_remarks: "some updated remarks", parking_spaces: 43, description: "some updated description", num_bedrooms: 43, high_speed_internet_available: false, patio: false, address: "some updated address", num_garages: 43, num_baths: 43, central_vac: false, eef_led_lighting: false}
  @invalid_attrs %{expires_on: nil, state: nil, new_construction: nil, fios_available: nil, tax_rate_code_area: nil, prop_tax_usd: nil, num_skylights: nil, lot_size: nil, attached_garage: nil, for_rent: nil, zip: nil, ext_urls: nil, visible_on: nil, city: nil, num_fireplaces: nil, modern_kitchen_countertops: nil, deck: nil, for_sale: nil, central_air: nil, stories: nil, num_half_baths: nil, year_built: nil, draft: false, pool: nil, mls_source_id: nil, security_system: nil, sq_ft: nil, studio: nil, cellular_coverage_quality: 10, hot_tub: nil, basement: nil, price_usd: nil, realtor_remarks: nil, parking_spaces: nil, description: nil, num_bedrooms: nil, high_speed_internet_available: nil, patio: nil, address: nil, num_garages: nil, num_baths: nil, central_vac: nil, eef_led_lighting: nil}

  setup %{conn: conn} do
    user = user_fixture()
    conn = assign(conn, :current_office, user.broker)
    conn = assign(conn, :current_user, user)
    {:ok, conn: conn, user: user}
  end

  def fixture(:listing, user) do
    {:ok, listing} = Realtor.create_listing(Enum.into(%{user_id: user.id, user: user, broker_id: user.broker.id, broker: user.broker}, @create_attrs))
    listing
  end

  def fixture(:listing, user, attrs \\ @create_attrs) do
    {:ok, listing} = Realtor.create_listing(Enum.into(%{user_id: user.id, user: user, broker_id: user.broker.id, broker: user.broker}, attrs))
    listing
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, listing_path(conn, :index)
    assert html_response(conn, 200) =~ ~r/Latest [0-9]+/
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

  test "re-renders values properly on validation fail with custom form elements", %{conn: initial_conn} do
    conn = initial_conn
    listing = fixture(:listing, conn.assigns.current_user)
    validation_failing_attrs = Enum.into(%{city: "custom123city", price_usd: nil, draft: false}, @update_attrs)
    conn = put conn, listing_path(conn, :update, listing), listing: validation_failing_attrs # should fail
    assert html_response(conn, 200) =~ "custom123city"
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

  test "client_listing URL with expired date in the future returns 200", %{conn: conn} do
    listing = fixture(:listing, conn.assigns.current_user)
    conn = get conn, public_client_listing_path(conn, :client_listing, public_client_listing_code(listing))
    assert html_response(conn, 200)
  end

  test "client_listing URL with expired date in the past returns 410", %{conn: conn} do
    listing = fixture(:listing, conn.assigns.current_user)
    conn = get conn, public_client_listing_path(conn, :client_listing, public_client_listing_code(listing, now_in_unix_epoch_days() - 1))
    assert response(conn, 410)
  end

  test "inspection sheet returns 200 and a relevant listing", %{conn: conn} do
    fixture(:listing, conn.assigns.current_user, @create_upcoming_broker_oh_attrs)
    conn = get conn, upcoming_inspections_path(conn, :inspection_sheet)
    assert response(conn, 200) =~ "inspectionaddress"
  end

end
