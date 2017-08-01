defmodule MpnetworkWeb.AttachmentControllerTest do

  # use ExUnit.Case, async: true

  use MpnetworkWeb.ConnCase, async: true

  alias Mpnetwork.{Listing, Realtor, Repo}
  import Mpnetwork.Test.Utilities

  # supposedly a png of a red dot
  @test_attachment_binary_data "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==" |> Base.decode64!
  # supposedly a gif
  @test_attachment_new_binary_data "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" |> Base.decode64!

  @listing_create_attrs %{expires_on: ~D[2010-04-17], state: "some state", new_construction: true, fios_available: true, tax_rate_code_area: 42, prop_tax_usd: 42, num_skylights: 42, lot_size: "420x240", attached_garage: true, for_rent: true, zip: "11050", ext_urls: ["some ext_urls"], visible_on: ~D[2010-04-17], city: "some city", num_fireplaces: 2, modern_kitchen_countertops: true, deck: true, for_sale: true, central_air: true, stories: 42, num_half_baths: 42, year_built: 42, draft: true, pool: true, mls_source_id: 42, security_system: true, sq_ft: 42, studio: true, cellular_coverage_quality: 3, hot_tub: true, basement: true, price_usd: 42, remarks: "some remarks", parking_spaces: 42, description: "some description", num_bedrooms: 42, high_speed_internet_available: true, patio: true, address: "some address", num_garages: 42, num_baths: 42, central_vac: true, eef_led_lighting: true}
  @create_attrs %{listing_id: 1, data: %{content_type: "image/png", path: "", filename: "test.png", binary: @test_attachment_binary_data}, original_filename: "some_original_filename.png", is_image: true, primary: false}
  @update_attrs %{listing_id: 1, data: %{content_type: "image/gif", path: "", filename: "test.gif", binary: @test_attachment_new_binary_data}, original_filename: "some_new_filename.gif", is_image: true, primary: true}
  @invalid_attrs %{listing_id: 1, content_type: nil, data: nil, height_pixels: nil, original_filename: nil, is_image: nil, primary: true, sha256_hash: nil, width_pixels: nil}

  setup %{conn: conn} do
    user = current_user()
    {:ok, conn: assign(conn, :current_user, user), user: user}
  end

  def fixture(:listing, user) do
    {:ok, listing} = Realtor.create_listing(Enum.into(%{user_id: user.id}, @listing_create_attrs))
    listing
  end

  def fixture(:attachment) do
    {:ok, attachment} = Listing.create_attachment(@create_attrs)
    attachment
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, attachment_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Attachments"
  end

  test "renders form for new attachments", %{conn: conn} do
    conn = get conn, attachment_path(conn, :new)
    assert html_response(conn, 200) =~ "New Attachment"
  end

  test "creates attachment and redirects to show when data is valid", %{conn: conn} do
    listing = fixture(:listing, conn.assigns.current_user)
    conn = post conn, attachment_path(conn, :create), attachment: Enum.into(%{listing_id: listing.id}, @create_attrs)
i html_response(conn, 200)
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == attachment_path(conn, :show, id)

    conn = get conn, attachment_path(conn, :show, id)
    assert html_response(conn, 200) =~ "some data"
  end

  test "does not create attachment and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, attachment_path(conn, :create), attachment: @invalid_attrs
    assert html_response(conn, 200) =~ "New Attachment"
  end

  test "renders form for editing chosen attachment", %{conn: conn} do
    attachment = fixture(:attachment)
    conn = get conn, attachment_path(conn, :edit, attachment)
    assert html_response(conn, 200) =~ "Edit Attachment"
  end

  test "updates chosen attachment and redirects when data is valid", %{conn: conn} do
    attachment = fixture(:attachment)
    conn = put conn, attachment_path(conn, :update, attachment), attachment: @update_attrs
    assert redirected_to(conn) == attachment_path(conn, :show, attachment)

    conn = get conn, attachment_path(conn, :show, attachment)
    assert html_response(conn, 200) =~ "some updated content_type"
  end

  test "does not update chosen attachment and renders errors when data is invalid", %{conn: conn} do
    attachment = fixture(:attachment)
    conn = put conn, attachment_path(conn, :update, attachment), attachment: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Attachment"
  end

  test "deletes chosen attachment", %{conn: conn} do
    attachment = fixture(:attachment)
    conn = delete conn, attachment_path(conn, :delete, attachment)
    assert redirected_to(conn) == attachment_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, attachment_path(conn, :show, attachment)
    end
  end
end
