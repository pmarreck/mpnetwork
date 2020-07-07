defmodule MpnetworkWeb.ListingControllerTest do
  # use ExUnit.Case, async: true

  use MpnetworkWeb.ConnCase, async: true

  import Mpnetwork.Test.Support.Utilities

  alias Mpnetwork.{Repo}
  alias Mpnetwork.Realtor.Listing
  # import Mpnetwork.Test.Support.Utilities
  alias Mpnetwork.Listing.LinkCodeGen

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
    address: "some address",
    num_garages: 42,
    num_baths: 42,
    central_vac: true,
    eef_led_lighting: true
  }
  @create_varchar_overflow_attrs Enum.into(
                                   %{appearance: String.duplicate("a", 256)},
                                   @create_attrs
                                 )
  @create_upcoming_broker_oh_attrs Enum.into(
                                     %{
                                       first_broker_oh_start_at:
                                         Timex.to_naive_datetime(
                                           Timex.shift(Timex.now(), hours: -2)
                                         ),
                                       first_broker_oh_mins: 60,
                                       address: "inspectionaddress",
                                       draft: false
                                     },
                                     @create_attrs
                                   )
  @create_upcoming_INVALID_broker_oh_attrs Enum.into(
                                             %{draft: true},
                                             @create_upcoming_broker_oh_attrs
                                           )
  @update_attrs %{
    listing_status_type: "CL",
    schools: "Man",
    prop_tax_usd: "100",
    vill_tax_usd: "100",
    section_num: "A",
    block_num: "2",
    lot_num: "B",
    live_at: ~N[2011-04-18 12:00:00],
    expires_on: ~D[2011-05-18],
    closed_on: ~D[2011-05-18],
    closing_price_usd: 1_000_000,
    state: "XX",
    new_construction: false,
    fios_available: false,
    tax_rate_code_area: 43,
    num_skylights: 43,
    lot_size: "430x720",
    attached_garage: false,
    for_rent: false,
    zip: "11030-1234",
    ext_urls: ["http://www.google.com"],
    city: "some updated city",
    num_fireplaces: 43,
    modern_kitchen_countertops: false,
    deck: false,
    for_sale: false,
    central_air: false,
    stories: 43,
    num_half_baths: 43,
    year_built: 1990,
    draft: true,
    pool: false,
    mls_source_id: 43,
    security_system: false,
    sq_ft: 43,
    studio: false,
    cellular_coverage_quality: 4,
    hot_tub: false,
    basement: false,
    price_usd: 43,
    realtor_remarks: "some updated remarks",
    parking_spaces: 43,
    description: "some updated description",
    num_bedrooms: 43,
    high_speed_internet_available: false,
    patio: false,
    address: "some updated address",
    num_garages: 43,
    num_baths: 43,
    central_vac: false,
    eef_led_lighting: false
  }
  @invalid_attrs %{
    listing_status_type: nil,
    expires_on: nil,
    state: nil,
    new_construction: nil,
    fios_available: nil,
    tax_rate_code_area: nil,
    prop_tax_usd: nil,
    num_skylights: nil,
    lot_size: nil,
    attached_garage: nil,
    for_rent: nil,
    zip: nil,
    ext_urls: nil,
    live_at: nil,
    city: nil,
    num_fireplaces: nil,
    modern_kitchen_countertops: nil,
    deck: nil,
    for_sale: nil,
    central_air: nil,
    stories: nil,
    num_half_baths: nil,
    year_built: nil,
    draft: false,
    pool: nil,
    mls_source_id: nil,
    security_system: nil,
    sq_ft: nil,
    studio: nil,
    cellular_coverage_quality: 10,
    hot_tub: nil,
    basement: nil,
    price_usd: nil,
    realtor_remarks: nil,
    parking_spaces: nil,
    description: nil,
    num_bedrooms: nil,
    high_speed_internet_available: nil,
    patio: nil,
    address: nil,
    num_garages: nil,
    num_baths: nil,
    central_vac: nil,
    eef_led_lighting: nil
  }

  setup %{conn: conn} do
    user = user_fixture()
    conn = assign(conn, :current_office, user.broker)
    conn = assign(conn, :current_user, user)
    {:ok, conn: conn, user: user}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get(conn, Routes.listing_path(conn, :index))
    assert html_response(conn, 200) =~ ~r/Latest [0-9]+/
  end

  test "renders form for new listings", %{conn: conn} do
    conn = get(conn, Routes.listing_path(conn, :new))
    assert html_response(conn, 200) =~ "Attachments can be added after saving the listing"
  end

  test "creates listing and redirects to show when data is valid", %{
    conn: original_conn,
    user: user
  } do
    conn = original_conn

    conn =
      post(
        conn,
        Routes.listing_path(conn, :create),
        listing: Enum.into(%{user_id: user.id, user: user}, @create_attrs)
      )

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == Routes.listing_path(conn, :show, id)
    conn = original_conn
    conn = get(conn, Routes.listing_path(conn, :show, id))
    assert html_response(conn, 200) =~ "some city"
  end

  test "does not create listing and renders errors when data is invalid", %{conn: conn} do
    conn = post(conn, Routes.listing_path(conn, :create), listing: @invalid_attrs)
    assert html_response(conn, 200) =~ "is invalid"
  end

  test "does not 500 if a varchar(255) field is exceeded", %{conn: conn} do
    conn = post(conn, Routes.listing_path(conn, :create), listing: @create_varchar_overflow_attrs)
    assert html_response(conn, 200) =~ "should be at most 255 character(s)"
  end

  test "renders form for editing chosen listing", %{conn: conn} do
    listing = fixture(:listing, conn.assigns.current_user)
    conn = get(conn, Routes.listing_path(conn, :edit, listing))
    assert html_response(conn, 200) =~ "listing[for_sale]"
  end

  test "updates chosen listing and redirects when data is valid", %{conn: initial_conn} do
    conn = initial_conn
    listing = fixture(:listing, conn.assigns.current_user)
    conn = put(conn, Routes.listing_path(conn, :update, listing), listing: @update_attrs)
    assert Repo.get(Listing, listing.id)
    assert redirected_to(conn) == Routes.listing_path(conn, :show, listing)

    conn = get(initial_conn, Routes.listing_path(initial_conn, :show, listing))
    assert html_response(conn, 200) =~ "XX"
  end

  test "does not update chosen listing and renders errors when data is invalid", %{conn: conn} do
    listing = fixture(:listing, conn.assigns.current_user)
    conn = put(conn, Routes.listing_path(conn, :update, listing), listing: @invalid_attrs)
    assert html_response(conn, 200) =~ "Oops"
  end

  test "re-renders values properly on validation fail with custom form elements", %{
    conn: initial_conn
  } do
    conn = initial_conn
    listing = fixture(:listing, conn.assigns.current_user)

    validation_failing_attrs =
      Enum.into(%{city: "custom123city", price_usd: nil, draft: false}, @update_attrs)

    # should fail
    conn = put(conn, Routes.listing_path(conn, :update, listing), listing: validation_failing_attrs)
    assert html_response(conn, 200) =~ "custom123city"
  end

  test "deletes chosen listing", %{conn: initial_conn} do
    conn = initial_conn
    listing = fixture(:listing, conn.assigns.current_user)
    conn = delete(conn, Routes.listing_path(conn, :delete, listing))
    assert redirected_to(conn) == Routes.listing_path(conn, :index)

    assert_error_sent(404, fn ->
      get(initial_conn, Routes.listing_path(initial_conn, :show, listing))
    end)
  end

  test "client_full URL with expired date in the future returns 200", %{conn: conn} do
    listing = fixture(:listing, conn.assigns.current_user)

    conn =
      get(conn, Routes.public_client_full_path(conn, :client_full, LinkCodeGen.public_client_full_code(listing)))

    assert html_response(conn, 200)
  end

  test "client_full URL with expired date in the past returns 410", %{conn: conn} do
    listing = fixture(:listing, conn.assigns.current_user)

    conn =
      get(
        conn,
        Routes.public_client_full_path(
          conn,
          :client_full,
          LinkCodeGen.public_client_full_code(listing, LinkCodeGen.now_in_unix_epoch_days() - 1)
        )
      )

    assert response(conn, 410)
  end

  test "inspection sheet returns 200 and a relevant listing from you", %{conn: conn} do
    fixture(:listing, conn.assigns.current_user, @create_upcoming_broker_oh_attrs)
    conn = get(conn, Routes.upcoming_inspections_path(conn, :inspection_sheet))
    assert response(conn, 200) =~ "inspectionaddress"
  end

  test "inspection sheet returns a relevant listing from someone else", %{conn: conn} do
    other_user = user_fixture()
    fixture(:listing, other_user, @create_upcoming_broker_oh_attrs)
    conn = get(conn, Routes.upcoming_inspections_path(conn, :inspection_sheet))
    assert response(conn, 200) =~ "inspectionaddress"
  end

  test "inspection sheet should never show draft listings", %{conn: conn} do
    fixture(:listing, conn.assigns.current_user, @create_upcoming_INVALID_broker_oh_attrs)
    conn = get(conn, Routes.upcoming_inspections_path(conn, :inspection_sheet))
    refute response(conn, 200) =~ "inspectionaddress"
  end

  test "office admins from two different offices can't edit each other's office's listings", %{
    conn: original_conn
  } do
    office_admin_1 = user_fixture(%{role_id: 2})
    office_admin_2 = user_fixture(%{role_id: 2})
    # assert office_admin_1.broker != office_admin_2.broker
    listing_1 =
      fixture(
        :listing,
        office_admin_1,
        Enum.into(%{draft: false, address: "shouldbeuneditablebyotheradmins"}, @create_attrs)
      )

    conn = assign(original_conn, :current_user, office_admin_1)
    conn = get(conn, Routes.listing_path(conn, :edit, listing_1))
    assert response(conn, 200) =~ "shouldbeuneditablebyotheradmins"
    conn = assign(original_conn, :current_user, office_admin_2)
    start_conn = conn
    conn = get(conn, Routes.listing_path(conn, :edit, listing_1))
    assert response(conn, 405)

    conn =
      put(
        start_conn,
        Routes.listing_path(conn, :update, listing_1),
        listing: %{address: "shouldn't be possible"}
      )

    assert response(conn, 405)
  end

  # note: what about draft listings?
  test "office admin from same office can edit anyone's listing in that office", %{conn: conn} do
    initial_conn = conn
    office = office_fixture()
    office_admin = user_fixture(%{role_id: 2, office_id: office.id, broker: office})
    realtor_in_same_office = user_fixture(%{role_id: 3, office_id: office.id, broker: office})
    listing = fixture(:listing, realtor_in_same_office)
    conn = conn |> assign(:current_user, office_admin)

    conn =
      put(conn, Routes.listing_path(conn, :update, listing), listing: %{address: "SHOULD be possible"})

    assert redirected_to(conn) == Routes.listing_path(conn, :show, listing)
    conn = get(initial_conn, Routes.listing_path(initial_conn, :show, listing))
    assert html_response(conn, 200) =~ "SHOULD be possible"
  end

  defp recycle_authenticated(conn, user), do: recycle(conn) |> assign(:current_user, user)

  test "actually can send emails", %{conn: conn} do
    import Mpnetwork.Listing.LinkCodeGen
    import Swoosh.TestAssertions
    office = office_fixture()
    user = user_fixture(%{role_id: 2, office_id: office.id, broker: office})
    listing = fixture(:listing, user)
    conn = conn |> assign(:current_user, user)
    original_authenticated_conn = conn
    conn = get(conn, Routes.email_listing_path(conn, :email_listing, listing))
    assert html_response(conn, 200) =~ "Preview the link"

    email = "test@mpwrealestateboard.network"
    name = "Peter Tester"
    names_emails = "#{name} <#{email}>"
    parsed_names_emails = [{"Peter Tester", "test@mpwrealestateboard.network"}]
    subject = "Property of Interest: #{listing.address}"

    body =
      "<p>Dear @name_placeholder,</p><p><br />\n</p><p><a href=\"@listing_link_placeholder\" target=\"_blank\">Please take a look!</a></p><p><br />\n</p><p>Regards,</p>#{
        conn.assigns.current_user.email_sig
      }"

    type = "broker"
    url = Routes.public_broker_full_url(conn, :broker_full, public_broker_full_code(listing))
    cc_self = false
    conn = original_authenticated_conn

    conn =
      post(conn, Routes.email_listing_path(conn, :send_email, listing), %{
        "id" => listing.id,
        "email" => %{
          "names_emails" => names_emails,
          "cc_self" => cc_self,
          "subject" => subject,
          "body" => body,
          "type" => type,
          "url" => url
        }
      })

    expected_redirect_path = Routes.listing_path(conn, :show, listing)
    assert redirected_to(conn) == expected_redirect_path
    # for some reason I couldn't just refer to original_authenticated_conn in the next line
    conn = get(recycle_authenticated(conn, user), expected_redirect_path)
    assert html_response(conn, 200) =~ "Listing emailed to these recipients successfully"
    assert_email_sent(to: parsed_names_emails, subject: subject)

    # Mpnetwork.ClientEmail.send_client(
    #   email, name, subject, body, user, listing, url, cc_self
    # )
  end
end
