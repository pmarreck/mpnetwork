defmodule Mpnetwork.ListingTest do

  use ExUnit.Case, async: true

  use Mpnetwork.DataCase

  alias Mpnetwork.{Listing, Upload, Realtor}

  import Mpnetwork.Test.Support.Utilities

  describe "attachments" do
    alias Mpnetwork.Listing.Attachment

    # supposedly a png of a red dot
    @test_attachment_binary_data "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==" |> Base.decode64!
    @test_attachment_binary_meta Upload.extract_meta_from_binary_data(@test_attachment_binary_data, "image")
    @test_attachment_sha256_hash Upload.sha256_hash(@test_attachment_binary_data)
    # supposedly a gif
    @test_attachment_new_binary_data "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" |> Base.decode64!
    @test_attachment_new_binary_meta Upload.extract_meta_from_binary_data(@test_attachment_new_binary_data, "image")
    @test_attachment_new_sha256_hash Upload.sha256_hash(@test_attachment_new_binary_data)

    @listing_create_attrs %{listing_status_type: "FS", schools: "Port", prop_tax_usd: "1000", vill_tax_usd: "1000", section_num: "1", block_num: "1", lot_num: "A", visible_on: ~D[2010-04-17], expires_on: ~D[2010-05-17], state: "NY", new_construction: true, fios_available: true, tax_rate_code_area: 42, num_skylights: 42, lot_size: "420x240", attached_garage: true, for_rent: true, zip: "11050", ext_urls: ["http://www.yahoo.com"], city: "some city", num_fireplaces: 2, modern_kitchen_countertops: true, deck: true, for_sale: true, central_air: true, stories: 42, num_half_baths: 42, year_built: 1984, draft: true, pool: true, mls_source_id: 42, security_system: true, sq_ft: 42, studio: true, cellular_coverage_quality: 3, hot_tub: true, basement: true, price_usd: 42, realtor_remarks: "some remarks", parking_spaces: 42, description: "some description", num_bedrooms: 42, high_speed_internet_available: true, patio: true, address: "N7 Mass Effect Galaxy", num_garages: 42, num_baths: 42, central_vac: true, eef_led_lighting: true}
    @post_create_attrs %{sha256_hash: Upload.sha256_hash(@test_attachment_binary_data), content_type: "image/png", data: %Upload{content_type: "image/png", filename: "test.png", binary: @test_attachment_binary_data}, original_filename: "some_original_filename.png", is_image: true, primary: true}
    @post_update_attrs %{sha256_hash: Upload.sha256_hash(@test_attachment_new_binary_data), content_type: "image/gif", data: %Upload{content_type: "image/gif", filename: "test.gif", binary: @test_attachment_new_binary_data}, original_filename: "some_new_filename.gif", is_image: true, primary: true}
    @attachment_create_attrs Enum.into(%{data: @test_attachment_binary_data}, @post_create_attrs)
    @attachment_update_attrs Enum.into(%{data: @test_attachment_new_binary_data}, @post_update_attrs)
    # @invalid_post_attrs Enum.into(%{data: nil}, @post_create_attrs)
    # @valid_attrs %{content_type: "some content_type", data: "some data", height_pixels: 42, original_filename: "some original_filename", primary: false, sha256_hash: "some sha256_hash", width_pixels: 42}
    # @update_attrs %{content_type: "some updated content_type", data: "some updated data", height_pixels: 43, original_filename: "some updated original_filename", primary: false, sha256_hash: "some updated sha256_hash", width_pixels: 43}
    @invalid_attrs %{content_type: nil, data: nil, height_pixels: nil, original_filename: nil, primary: nil, sha256_hash: nil, width_pixels: nil}

    def attachment_fixture(attrs \\ %{}) do
      {:ok, attachment} =
        attrs
        |> Enum.into(@attachment_create_attrs)
        |> Listing.create_attachment()
      attachment
    end

    def fixture(:listing, user \\ user_fixture()) do
      {:ok, listing} = Realtor.create_listing(Enum.into(%{user_id: user.id, broker_id: user.office_id}, @listing_create_attrs))
      listing
    end

    test "list_attachments/0 returns all attachments" do
      listing = fixture(:listing)
      attachment = attachment_fixture(%{listing_id: listing.id})
      assert Listing.list_attachments(listing.id) == [attachment]
    end

    test "get_attachment!/1 returns the attachment with given id" do
      listing = fixture(:listing)
      attachment = attachment_fixture(%{listing_id: listing.id})
      assert Listing.get_attachment!(attachment.id) == attachment
    end

    test "create_attachment/1 with valid data creates an attachment" do
      listing = fixture(:listing)
      {c_t, w, h} = @test_attachment_binary_meta
      assert {:ok, %Attachment{} = attachment} = Listing.create_attachment(Enum.into(%{listing_id: listing.id, content_type: c_t, width_pixels: w, height_pixels: h}, @attachment_create_attrs))
      assert attachment.content_type == c_t
      assert attachment.data == @test_attachment_binary_data
      assert attachment.height_pixels == 5
      assert attachment.original_filename == "some_original_filename.png"
      assert attachment.primary == true
      assert attachment.sha256_hash == @test_attachment_sha256_hash
      assert attachment.width_pixels == 5
    end

    test "create_attachment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Listing.create_attachment(@invalid_attrs)
    end

    test "update_attachment/2 with valid data updates the attachment" do
      listing = fixture(:listing)
      attachment = attachment_fixture(%{listing_id: listing.id})
      {c_t, w, h} = @test_attachment_new_binary_meta
      assert {:ok, %Attachment{} = attachment} = Listing.update_attachment(attachment, Enum.into(%{listing_id: listing.id, content_type: c_t, width_pixels: w, height_pixels: h}, @attachment_update_attrs))
      assert attachment.content_type == "image/gif"
      assert attachment.data == @test_attachment_new_binary_data
      assert attachment.height_pixels == 1
      assert attachment.original_filename == "some_new_filename.gif"
      assert attachment.primary == true
      assert attachment.sha256_hash == @test_attachment_new_sha256_hash
      assert attachment.width_pixels == 1
    end

    test "update_attachment/2 with invalid data returns error changeset" do
      listing = fixture(:listing)
      attachment = attachment_fixture(%{listing_id: listing.id})
      assert {:error, %Ecto.Changeset{}} = Listing.update_attachment(attachment, @invalid_attrs)
      assert attachment == Listing.get_attachment!(attachment.id)
    end

    test "delete_attachment/1 deletes the attachment" do
      listing = fixture(:listing)
      attachment = attachment_fixture(%{listing_id: listing.id})
      assert {:ok, %Attachment{}} = Listing.delete_attachment(attachment)
      assert_raise Ecto.NoResultsError, fn -> Listing.get_attachment!(attachment.id) end
    end

    test "change_attachment/1 returns a attachment changeset" do
      listing = fixture(:listing)
      attachment = attachment_fixture(%{listing_id: listing.id})
      assert %Ecto.Changeset{} = Listing.change_attachment(attachment)
    end
  end
end
