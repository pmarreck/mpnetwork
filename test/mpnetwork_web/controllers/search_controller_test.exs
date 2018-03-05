defmodule MpnetworkWeb.SearchControllerTest do
  use MpnetworkWeb.ConnCase, async: true

  import Mpnetwork.Test.Support.Utilities

  alias Mpnetwork.Realtor

  @create_attrs %{
    listing_status_type: "FS",
    schools: "Port",
    prop_tax_usd: "1000",
    vill_tax_usd: "1000",
    section_num: "1",
    block_num: "1",
    lot_num: "A",
    live_at: ~N[2017-11-17 12:00:00],
    expires_on: ~D[2018-04-17],
    state: "NY",
    new_construction: true,
    fios_available: true,
    tax_rate_code_area: 42,
    num_skylights: 42,
    lot_size: "420x240",
    attached_garage: true,
    for_rent: true,
    zip: "11050",
    ext_urls: ["http://www.yahoo.com"],
    city: "some city",
    num_fireplaces: 2,
    modern_kitchen_countertops: true,
    deck: true,
    for_sale: true,
    central_air: true,
    stories: 42,
    num_half_baths: 42,
    year_built: 1984,
    draft: true,
    pool: true,
    mls_source_id: 42,
    security_system: true,
    sq_ft: 42,
    studio: true,
    cellular_coverage_quality: 3,
    hot_tub: true,
    basement: true,
    price_usd: 42,
    realtor_remarks: "some remarks",
    parking_spaces: 42,
    description: "some description",
    num_bedrooms: 42,
    high_speed_internet_available: true,
    patio: true,
    address: "Search Result Address",
    num_garages: 42,
    num_baths: 42,
    central_vac: true,
    eef_led_lighting: true
  }

  def fixture(:listing, user) do
    {:ok, listing} =
      Realtor.create_listing(
        Enum.into(
          %{user_id: user.id, user: user, broker_id: user.broker.id, broker: user.broker},
          @create_attrs
        )
      )

    listing
  end

  test "search of a blank works", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> assign(:current_user, user)
      |> get(listing_path(conn, :index, %{q: ""}))

    assert html_response(conn, 200) =~ "No listings"
  end

  test "search of an actual attribute works", %{conn: conn} do
    user = user_fixture()
    _listing = fixture(:listing, user)

    conn =
      conn
      |> assign(:current_user, user)
      |> get(listing_path(conn, :index, %{q: "FS"}))

    assert html_response(conn, 200) =~ "Search Result Address"
  end
end
