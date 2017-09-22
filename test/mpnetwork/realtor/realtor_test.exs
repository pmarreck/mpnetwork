defmodule Mpnetwork.RealtorTest do
  use Mpnetwork.DataCase

  alias Mpnetwork.Realtor

  @valid_user_attrs %{email: "test@example.com", password: "unit test all the things!", password_confirmation: "unit test all the things!"}

  defp user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_user_attrs)
        |> Realtor.create_user()
      user
  end

  describe "broadcasts" do
    alias Mpnetwork.Realtor.Broadcast

    @valid_attrs %{body: "some body", title: "some title"}
    @update_attrs %{body: "some updated body", title: "some updated title"}
    @invalid_attrs %{body: nil, title: nil}

    def broadcast_fixture(attrs \\ %{}) do
      # first add an associated user if none exists
      attrs = unless attrs[:user_id] do
        user = user_fixture()
        Enum.into(%{user_id: user.id}, attrs)
      else
        attrs
      end
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
      user = user_fixture()
      valid_attrs_with_user_id = Enum.into(%{user_id: user.id}, @valid_attrs)
      assert {:ok, %Broadcast{} = broadcast} = Realtor.create_broadcast(valid_attrs_with_user_id)
      assert broadcast.body == "some body"
      assert broadcast.title == "some title"
      assert broadcast.user_id != nil
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
      assert broadcast.user_id != nil
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

    @valid_attrs %{expires_on: ~D[2017-09-17], state: "NY", new_construction: false, fios_available: true, tax_rate_code_area: 42, prop_tax_usd: 42, num_skylights: 42, lot_size: "42x42", attached_garage: true, for_rent: true, zip: "11050", ext_urls: ["http://ext_urls"], visible_on: ~D[2018-04-17], city: "New York", num_fireplaces: 3, modern_kitchen_countertops: true, deck: true, for_sale: true, central_air: true, stories: 2, num_half_baths: 2, year_built: 1993, draft: false, pool: true, mls_source_id: 42, security_system: true, sq_ft: 42, studio: false, cellular_coverage_quality: 3, hot_tub: true, basement: true, price_usd: 1000000, remarks: "some remarks", parking_spaces: 6, description: "some description", num_bedrooms: 42, high_speed_internet_available: true, patio: true, address: "1 Fancy Place", num_garages: 4, num_baths: 5, central_vac: true, eef_led_lighting: true}
    @update_attrs %{expires_on: ~D[2011-05-18], state: "some updated state", new_construction: false, fios_available: false, tax_rate_code_area: 43, prop_tax_usd: 43, num_skylights: 43, lot_size: "43x43", attached_garage: false, for_rent: false, zip: "some updated zip", ext_urls: ["http://updated_ext_urls"], visible_on: ~D[2011-05-18], city: "some updated city", num_fireplaces: 43, modern_kitchen_countertops: false, deck: false, for_sale: false, central_air: false, stories: 43, num_half_baths: 43, year_built: 43, draft: false, pool: false, mls_source_id: 43, security_system: false, sq_ft: 43, studio: false, cellular_coverage_quality: 4, hot_tub: false, basement: false, price_usd: 43, remarks: "some updated remarks", parking_spaces: 43, description: "some updated description", num_bedrooms: 43, high_speed_internet_available: false, patio: false, address: "some updated address", num_garages: 43, num_baths: 43, central_vac: false, eef_led_lighting: false}
    @invalid_attrs %{expires_on: nil, state: nil, new_construction: nil, fios_available: nil, tax_rate_code_area: nil, prop_tax_usd: nil, num_skylights: nil, lot_size: nil, attached_garage: nil, for_rent: nil, zip: nil, ext_urls: nil, visible_on: nil, city: nil, num_fireplaces: nil, modern_kitchen_countertops: nil, deck: nil, for_sale: nil, central_air: nil, stories: nil, num_half_baths: nil, year_built: nil, draft: nil, pool: nil, mls_source_id: nil, security_system: nil, sq_ft: nil, studio: nil, cellular_coverage_quality: nil, hot_tub: nil, basement: nil, price_usd: nil, remarks: nil, parking_spaces: nil, description: nil, num_bedrooms: nil, high_speed_internet_available: nil, patio: nil, address: nil, num_garages: nil, num_baths: nil, central_vac: nil, eef_led_lighting: nil}

    def listing_fixture(attrs \\ %{}) do
      # first add an associated user if none exists
      attrs = unless attrs[:user_id] || attrs[:user] do
        user = user_fixture()
        Enum.into(%{user_id: user.id, user: user}, attrs)
      else
        attrs
      end
      # next add an associated office if none exists
      attrs = unless attrs[:broker_id] || attrs[:broker] do
        broker = office_fixture()
        Enum.into(%{broker_id: broker.id, broker: broker}, attrs)
      else
        attrs
      end
      {:ok, listing} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Realtor.create_listing()
      listing |> Repo.preload([:broker, :user])
    end

    test "list_listings/2 returns all listings" do
      listing = listing_fixture()
      assert Realtor.list_latest_listings(nil, 10) == [listing]
    end

    test "get_listing!/1 returns the listing with given id" do
      listing = listing_fixture() |> Repo.preload([:user, :broker])
      assert Realtor.get_listing!(listing.id) == listing
    end

    test "create_listing/1 with valid data creates a listing" do
      user = user_fixture()
      office = office_fixture()
      valid_attrs_with_user_id_and_broker_id = Enum.into(%{user_id: user.id, broker_id: office.id}, @valid_attrs)
      assert {:ok, %Listing{} = listing} = Realtor.create_listing(valid_attrs_with_user_id_and_broker_id)
      assert listing.expires_on == ~D[2017-09-17]
      assert listing.state == "NY"
      assert listing.new_construction == false
      assert listing.fios_available == true
      assert listing.tax_rate_code_area == 42
      assert listing.prop_tax_usd == 42
      assert listing.num_skylights == 42
      assert listing.lot_size == "42x42"
      assert listing.attached_garage == true
      assert listing.for_rent == true
      assert listing.zip == "11050"
      assert listing.ext_urls == ["http://ext_urls"]
      assert listing.visible_on == ~D[2018-04-17]
      assert listing.city == "New York"
      assert listing.num_fireplaces == 3
      assert listing.modern_kitchen_countertops == true
      assert listing.deck == true
      assert listing.for_sale == true
      assert listing.central_air == true
      assert listing.stories == 2
      assert listing.num_half_baths == 2
      assert listing.year_built == 1993
      assert listing.draft == false
      assert listing.pool == true
      assert listing.mls_source_id == 42
      assert listing.security_system == true
      assert listing.sq_ft == 42
      assert listing.studio == false
      assert listing.cellular_coverage_quality == 3
      assert listing.hot_tub == true
      assert listing.basement == true
      assert listing.price_usd == 1000000
      assert listing.remarks == "some remarks"
      assert listing.parking_spaces == 6
      assert listing.description == "some description"
      assert listing.num_bedrooms == 42
      assert listing.high_speed_internet_available == true
      assert listing.patio == true
      assert listing.address == "1 Fancy Place"
      assert listing.num_garages == 4
      assert listing.num_baths == 5
      assert listing.central_vac == true
      assert listing.eef_led_lighting == true
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
      assert listing.prop_tax_usd == 43
      assert listing.num_skylights == 43
      assert listing.lot_size == "43x43"
      assert listing.attached_garage == false
      assert listing.for_rent == false
      assert listing.zip == "some updated zip"
      assert listing.ext_urls == ["http://updated_ext_urls"]
      assert listing.visible_on == ~D[2011-05-18]
      assert listing.city == "some updated city"
      assert listing.num_fireplaces == 43
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
      assert listing.cellular_coverage_quality == 4
      assert listing.hot_tub == false
      assert listing.basement == false
      assert listing.price_usd == 43
      assert listing.remarks == "some updated remarks"
      assert listing.parking_spaces == 43
      assert listing.description == "some updated description"
      assert listing.num_bedrooms == 43
      assert listing.high_speed_internet_available == false
      assert listing.patio == false
      assert listing.address == "some updated address"
      assert listing.num_garages == 43
      assert listing.num_baths == 43
      assert listing.central_vac == false
      assert listing.eef_led_lighting == false
    end

    test "update_listing/2 with invalid data returns error changeset" do
      listing = listing_fixture() |> Repo.preload([:user, :broker])
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

  describe "offices" do
    alias Mpnetwork.Realtor.Office

    @valid_attrs %{address: "some address", city: "some city", name: "some name", phone: "some phone", state: "some state", zip: "some zip"}
    @update_attrs %{address: "some updated address", city: "some updated city", name: "some updated name", phone: "some updated phone", state: "some updated state", zip: "some updated zip"}
    @invalid_attrs %{address: nil, city: nil, name: nil, phone: nil, state: nil, zip: nil}

    def office_fixture(attrs \\ %{}) do
      {:ok, office} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Realtor.create_office()
      office
    end

    test "list_offices/0 returns all offices" do
      office = office_fixture()
      assert Realtor.list_offices() == [office]
    end

    test "get_office!/1 returns the office with given id" do
      office = office_fixture()
      assert Realtor.get_office!(office.id) == office
    end

    test "create_office/1 with valid data creates a office" do
      assert {:ok, %Office{} = office} = Realtor.create_office(@valid_attrs)
      assert office.address == "some address"
      assert office.city == "some city"
      assert office.name == "some name"
      assert office.phone == "some phone"
      assert office.state == "some state"
      assert office.zip == "some zip"
    end

    test "create_office/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Realtor.create_office(@invalid_attrs)
    end

    test "update_office/2 with valid data updates the office" do
      office = office_fixture()
      assert {:ok, office} = Realtor.update_office(office, @update_attrs)
      assert %Office{} = office
      assert office.address == "some updated address"
      assert office.city == "some updated city"
      assert office.name == "some updated name"
      assert office.phone == "some updated phone"
      assert office.state == "some updated state"
      assert office.zip == "some updated zip"
    end

    test "update_office/2 with invalid data returns error changeset" do
      office = office_fixture()
      assert {:error, %Ecto.Changeset{}} = Realtor.update_office(office, @invalid_attrs)
      assert office == Realtor.get_office!(office.id)
    end

    test "delete_office/1 deletes the office" do
      office = office_fixture()
      assert {:ok, %Office{}} = Realtor.delete_office(office)
      assert_raise Ecto.NoResultsError, fn -> Realtor.get_office!(office.id) end
    end

    test "change_office/1 returns a office changeset" do
      office = office_fixture()
      assert %Ecto.Changeset{} = Realtor.change_office(office)
    end
  end
end
