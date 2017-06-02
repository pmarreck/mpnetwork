defmodule Mpnetwork.RealtorTest do
  use Mpnetwork.DataCase

  alias Mpnetwork.Realtor

  describe "broadcasts" do
    alias Mpnetwork.Realtor.Broadcast

    @valid_attrs %{body: "some body", title: "some title", user_id: 42}
    @update_attrs %{body: "some updated body", title: "some updated title", user_id: 43}
    @invalid_attrs %{body: nil, title: nil, user_id: nil}

    def broadcast_fixture(attrs \\ %{}) do
      {:ok, broadcast} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Realtor.create_broadcast()

      broadcast
    end

    test "list_broadcasts/0 returns all broadcasts" do
      broadcast = broadcast_fixture()
      assert Realtor.list_broadcasts() == [broadcast]
    end

    test "get_broadcast!/1 returns the broadcast with given id" do
      broadcast = broadcast_fixture()
      assert Realtor.get_broadcast!(broadcast.id) == broadcast
    end

    test "create_broadcast/1 with valid data creates a broadcast" do
      assert {:ok, %Broadcast{} = broadcast} = Realtor.create_broadcast(@valid_attrs)
      assert broadcast.body == "some body"
      assert broadcast.title == "some title"
      assert broadcast.user_id == 42
    end

    test "create_broadcast/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Realtor.create_broadcast(@invalid_attrs)
    end

    test "update_broadcast/2 with valid data updates the broadcast" do
      broadcast = broadcast_fixture()
      assert {:ok, broadcast} = Realtor.update_broadcast(broadcast, @update_attrs)
      assert %Broadcast{} = broadcast
      assert broadcast.body == "some updated body"
      assert broadcast.title == "some updated title"
      assert broadcast.user_id == 43
    end

    test "update_broadcast/2 with invalid data returns error changeset" do
      broadcast = broadcast_fixture()
      assert {:error, %Ecto.Changeset{}} = Realtor.update_broadcast(broadcast, @invalid_attrs)
      assert broadcast == Realtor.get_broadcast!(broadcast.id)
    end

    test "delete_broadcast/1 deletes the broadcast" do
      broadcast = broadcast_fixture()
      assert {:ok, %Broadcast{}} = Realtor.delete_broadcast(broadcast)
      assert_raise Ecto.NoResultsError, fn -> Realtor.get_broadcast!(broadcast.id) end
    end

    test "change_broadcast/1 returns a broadcast changeset" do
      broadcast = broadcast_fixture()
      assert %Ecto.Changeset{} = Realtor.change_broadcast(broadcast)
    end
  end

  describe "listings" do
    alias Mpnetwork.Realtor.Listing

    @valid_attrs %{expires_on: ~D[2010-04-17], state: "some state", new_construction: true, fios_available: true, tax_rate_code_area: 42, total_annual_property_taxes_usd: 42, num_skylights: 42, lot_size_acre_cents: 42, attached_garage: true, for_rent: true, zip: "some zip", ext_url: "some ext_url", visible_on: ~D[2010-04-17], city: "some city", fireplaces: 42, new_appliances: true, modern_kitchen_countertops: true, deck: true, for_sale: true, central_air: true, stories: 42, num_half_baths: 42, year_built: 42, draft: true, pool: true, mls_source_id: 42, security_system: true, sq_ft: 42, studio: true, cellular_coverage_quality: 42, hot_tub: true, basement: true, price_usd: 42, special_notes: "some special_notes", parking_spaces: 42, description: "some description", num_bedrooms: 42, high_speed_internet_available: true, patio: true, address: "some address", num_garages: 42, num_baths: 42, central_vac: true, led_lighting: true}
    @update_attrs %{expires_on: ~D[2011-05-18], state: "some updated state", new_construction: false, fios_available: false, tax_rate_code_area: 43, total_annual_property_taxes_usd: 43, num_skylights: 43, lot_size_acre_cents: 43, attached_garage: false, for_rent: false, zip: "some updated zip", ext_url: "some updated ext_url", visible_on: ~D[2011-05-18], city: "some updated city", fireplaces: 43, new_appliances: false, modern_kitchen_countertops: false, deck: false, for_sale: false, central_air: false, stories: 43, num_half_baths: 43, year_built: 43, draft: false, pool: false, mls_source_id: 43, security_system: false, sq_ft: 43, studio: false, cellular_coverage_quality: 43, hot_tub: false, basement: false, price_usd: 43, special_notes: "some updated special_notes", parking_spaces: 43, description: "some updated description", num_bedrooms: 43, high_speed_internet_available: false, patio: false, address: "some updated address", num_garages: 43, num_baths: 43, central_vac: false, led_lighting: false}
    @invalid_attrs %{expires_on: nil, state: nil, new_construction: nil, fios_available: nil, tax_rate_code_area: nil, total_annual_property_taxes_usd: nil, num_skylights: nil, lot_size_acre_cents: nil, attached_garage: nil, for_rent: nil, zip: nil, ext_url: nil, visible_on: nil, city: nil, fireplaces: nil, new_appliances: nil, modern_kitchen_countertops: nil, deck: nil, for_sale: nil, central_air: nil, stories: nil, num_half_baths: nil, year_built: nil, draft: nil, pool: nil, mls_source_id: nil, security_system: nil, sq_ft: nil, studio: nil, cellular_coverage_quality: nil, hot_tub: nil, basement: nil, price_usd: nil, special_notes: nil, parking_spaces: nil, description: nil, num_bedrooms: nil, high_speed_internet_available: nil, patio: nil, address: nil, num_garages: nil, num_baths: nil, central_vac: nil, led_lighting: nil}

    def listing_fixture(attrs \\ %{}) do
      {:ok, listing} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Realtor.create_listing()

      listing
    end

    test "list_listings/0 returns all listings" do
      listing = listing_fixture()
      assert Realtor.list_listings() == [listing]
    end

    test "get_listing!/1 returns the listing with given id" do
      listing = listing_fixture()
      assert Realtor.get_listing!(listing.id) == listing
    end

    test "create_listing/1 with valid data creates a listing" do
      assert {:ok, %Listing{} = listing} = Realtor.create_listing(@valid_attrs)
      assert listing.expires_on == ~D[2010-04-17]
      assert listing.state == "some state"
      assert listing.new_construction == true
      assert listing.fios_available == true
      assert listing.tax_rate_code_area == 42
      assert listing.total_annual_property_taxes_usd == 42
      assert listing.num_skylights == 42
      assert listing.lot_size_acre_cents == 42
      assert listing.attached_garage == true
      assert listing.for_rent == true
      assert listing.zip == "some zip"
      assert listing.ext_url == "some ext_url"
      assert listing.visible_on == ~D[2010-04-17]
      assert listing.city == "some city"
      assert listing.fireplaces == 42
      assert listing.new_appliances == true
      assert listing.modern_kitchen_countertops == true
      assert listing.deck == true
      assert listing.for_sale == true
      assert listing.central_air == true
      assert listing.stories == 42
      assert listing.num_half_baths == 42
      assert listing.year_built == 42
      assert listing.draft == true
      assert listing.pool == true
      assert listing.mls_source_id == 42
      assert listing.security_system == true
      assert listing.sq_ft == 42
      assert listing.studio == true
      assert listing.cellular_coverage_quality == 42
      assert listing.hot_tub == true
      assert listing.basement == true
      assert listing.price_usd == 42
      assert listing.special_notes == "some special_notes"
      assert listing.parking_spaces == 42
      assert listing.description == "some description"
      assert listing.num_bedrooms == 42
      assert listing.high_speed_internet_available == true
      assert listing.patio == true
      assert listing.address == "some address"
      assert listing.num_garages == 42
      assert listing.num_baths == 42
      assert listing.central_vac == true
      assert listing.led_lighting == true
    end

    test "create_listing/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Realtor.create_listing(@invalid_attrs)
    end

    test "update_listing/2 with valid data updates the listing" do
      listing = listing_fixture()
      assert {:ok, listing} = Realtor.update_listing(listing, @update_attrs)
      assert %Listing{} = listing
      assert listing.expires_on == ~D[2011-05-18]
      assert listing.state == "some updated state"
      assert listing.new_construction == false
      assert listing.fios_available == false
      assert listing.tax_rate_code_area == 43
      assert listing.total_annual_property_taxes_usd == 43
      assert listing.num_skylights == 43
      assert listing.lot_size_acre_cents == 43
      assert listing.attached_garage == false
      assert listing.for_rent == false
      assert listing.zip == "some updated zip"
      assert listing.ext_url == "some updated ext_url"
      assert listing.visible_on == ~D[2011-05-18]
      assert listing.city == "some updated city"
      assert listing.fireplaces == 43
      assert listing.new_appliances == false
      assert listing.modern_kitchen_countertops == false
      assert listing.deck == false
      assert listing.for_sale == false
      assert listing.central_air == false
      assert listing.stories == 43
      assert listing.num_half_baths == 43
      assert listing.year_built == 43
      assert listing.draft == false
      assert listing.pool == false
      assert listing.mls_source_id == 43
      assert listing.security_system == false
      assert listing.sq_ft == 43
      assert listing.studio == false
      assert listing.cellular_coverage_quality == 43
      assert listing.hot_tub == false
      assert listing.basement == false
      assert listing.price_usd == 43
      assert listing.special_notes == "some updated special_notes"
      assert listing.parking_spaces == 43
      assert listing.description == "some updated description"
      assert listing.num_bedrooms == 43
      assert listing.high_speed_internet_available == false
      assert listing.patio == false
      assert listing.address == "some updated address"
      assert listing.num_garages == 43
      assert listing.num_baths == 43
      assert listing.central_vac == false
      assert listing.led_lighting == false
    end

    test "update_listing/2 with invalid data returns error changeset" do
      listing = listing_fixture()
      assert {:error, %Ecto.Changeset{}} = Realtor.update_listing(listing, @invalid_attrs)
      assert listing == Realtor.get_listing!(listing.id)
    end

    test "delete_listing/1 deletes the listing" do
      listing = listing_fixture()
      assert {:ok, %Listing{}} = Realtor.delete_listing(listing)
      assert_raise Ecto.NoResultsError, fn -> Realtor.get_listing!(listing.id) end
    end

    test "change_listing/1 returns a listing changeset" do
      listing = listing_fixture()
      assert %Ecto.Changeset{} = Realtor.change_listing(listing)
    end
  end
end
