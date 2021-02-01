defmodule Mpnetwork.RealtorTest do
  use Mpnetwork.DataCase, async: true

  alias Mpnetwork.{Realtor, User}

  import Mpnetwork.Test.Support.Utilities

  describe "broadcasts" do
    alias Mpnetwork.Realtor.Broadcast

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
      valid_attrs_with_user_id = Enum.into(%{user_id: user.id}, valid_broadcast_attrs())
      assert {:ok, %Broadcast{} = broadcast} = Realtor.create_broadcast(valid_attrs_with_user_id)
      assert broadcast.body == "some broadcast body"
      assert broadcast.title == "some broadcast title"
      assert broadcast.user_id != nil
    end

    test "create_broadcast/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Realtor.create_broadcast(invalid_broadcast_attrs())
    end

    test "update_broadcast/2 with valid data updates the broadcast" do
      broadcast = broadcast_fixture()

      assert {:ok, broadcast} =
               Realtor.update_broadcast(broadcast, valid_update_broadcast_attrs())

      assert %Broadcast{} = broadcast
      assert broadcast.body == "some updated broadcast body"
      assert broadcast.title == "some updated broadcast title"
      assert broadcast.user_id != nil
    end

    test "update_broadcast/2 with invalid data returns error changeset" do
      broadcast = broadcast_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Realtor.update_broadcast(broadcast, invalid_broadcast_attrs())

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

    @valid_attrs %{
      listing_status_type: "FS",
      schools: "Port",
      prop_tax_usd: "1000",
      vill_tax_usd: "1000",
      section_num: "1",
      block_num: "1",
      lot_num: "A",
      live_at: ~N[2017-04-17 12:00:00.000000],
      expires_on: ~D[2017-05-17],
      state: "NY",
      new_construction: false,
      fios_available: true,
      tax_rate_code_area: 42,
      num_skylights: 42,
      lot_size: "42x42",
      attached_garage: true,
      for_rent: false,
      zip: "11050",
      ext_urls: ["http://www.yahoo.com"],
      city: "New York",
      num_fireplaces: 3,
      modern_kitchen_countertops: true,
      deck: true,
      for_sale: true,
      central_air: true,
      stories: 2,
      num_half_baths: 2,
      year_built: 1993,
      draft: false,
      pool: true,
      mls_source_id: 42,
      security_system: true,
      sq_ft: 42,
      studio: false,
      cellular_coverage_quality: 3,
      hot_tub: true,
      basement: true,
      price_usd: 1_000_000,
      realtor_remarks: "some realtor_remarks",
      parking_spaces: 6,
      description: "some description",
      num_bedrooms: 42,
      high_speed_internet_available: true,
      patio: true,
      address: "1 Fancy Place",
      num_garages: 4,
      num_baths: 5,
      central_vac: true,
      eef_led_lighting: true,
      sec_dep: nil,
      commission_paid_by: nil,
      rental_available_on: nil,
    }

    @valid_rental_attrs %{@valid_attrs | listing_status_type: "NEW", for_sale: false, for_rent: true, prop_tax_usd: nil, vill_tax_usd: nil, section_num: nil, block_num: nil, lot_num: nil,
      sec_dep: "1/2 rent", commission_paid_by: "L", rental_available_on: ~D[2018-04-01]}

    @update_attrs %{
      listing_status_type: "NEW",
      schools: "Man",
      prop_tax_usd: "100",
      vill_tax_usd: "100",
      section_num: "B",
      block_num: "2",
      lot_num: "D",
      live_at: ~N[2017-04-17 12:00:00.000000],
      expires_on: ~D[2017-09-17],
      state: "XX",
      new_construction: false,
      fios_available: false,
      tax_rate_code_area: 43,
      num_skylights: 43,
      lot_size: "43x43",
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
      year_built: 2000,
      draft: false,
      pool: false,
      mls_source_id: 43,
      security_system: false,
      sq_ft: 43,
      studio: false,
      cellular_coverage_quality: 4,
      hot_tub: false,
      basement: false,
      price_usd: 43,
      realtor_remarks: "some updated realtor_remarks",
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
      live_at: nil,
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
      city: nil,
      num_fireplaces: nil,
      modern_kitchen_countertops: nil,
      deck: nil,
      for_sale: nil,
      central_air: nil,
      stories: nil,
      num_half_baths: nil,
      year_built: nil,
      draft: nil,
      pool: nil,
      mls_source_id: nil,
      security_system: nil,
      sq_ft: nil,
      studio: nil,
      cellular_coverage_quality: nil,
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

    defp with_listing_preloads(listing) do
      listing |> Repo.preload([:broker, :user])
    end

    def listing_fixture(attrs \\ %{}) do
      # first add an associated user if none exists
      attrs =
        unless attrs[:user_id] || attrs[:user] do
          user = user_fixture()
          attrs |> Map.merge(%{user_id: user.id, user: user})
        else
          attrs
        end

      # next add an associated office if none exists
      attrs =
        unless attrs[:broker_id] || attrs[:broker] do
          broker = office_fixture()
          attrs |> Map.merge(%{broker_id: broker.id, broker: broker})
        else
          attrs
        end

      {:ok, listing} =
        @valid_attrs
        |> Map.merge(attrs)
        |> Realtor.create_listing()

      listing
    end

    test "list_listings/2 returns all listings" do
      listing = listing_fixture() |> with_listing_preloads
      assert Realtor.list_latest_listings(nil, 10) == [listing]
    end

    test "get_listing!/1 returns the listing with given id" do
      listing = listing_fixture()
      assert Realtor.get_listing!(listing.id) == listing
    end

    test "create_listing/1 with valid data creates a listing" do
      user = user_fixture()
      office = office_fixture()

      valid_attrs_with_user_id_and_broker_id =
        Enum.into(%{user_id: user.id, broker_id: office.id}, @valid_attrs)

      assert {:ok, %Listing{} = listing} =
               Realtor.create_listing(valid_attrs_with_user_id_and_broker_id)

      assert listing.expires_on == ~D[2017-05-17]
      assert listing.state == "NY"
      assert listing.new_construction == false
      assert listing.fios_available == true
      assert listing.tax_rate_code_area == 42
      assert listing.prop_tax_usd == 1000
      assert listing.num_skylights == 42
      assert listing.lot_size == "42x42"
      assert listing.attached_garage == true
      assert listing.for_rent == false
      assert listing.zip == "11050"
      assert listing.ext_urls == ["http://www.yahoo.com"]
      assert listing.live_at == ~N[2017-04-17 12:00:00]
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
      assert listing.price_usd == 1_000_000
      assert listing.realtor_remarks == "some realtor_remarks"
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

    test "create_listing/1 with valid rental data creates a listing" do
      user = user_fixture()
      office = office_fixture()

      valid_attrs_with_user_id_and_broker_id =
        Enum.into(%{user_id: user.id, broker_id: office.id}, @valid_rental_attrs)

      assert {:ok, %Listing{} = listing} =
               Realtor.create_listing(valid_attrs_with_user_id_and_broker_id)

      assert listing.for_rent == true
      assert listing.for_sale == false
      assert listing.prop_tax_usd == nil
      assert listing.vill_tax_usd == nil
      assert listing.section_num == nil
      assert listing.block_num == nil
      assert listing.lot_num == nil
      assert listing.sec_dep == "1/2 rent"
      assert listing.commission_paid_by == "L"
    end

    test "update_listing/2 with valid data updates the listing" do
      listing = listing_fixture()
      assert {:ok, listing} = Realtor.update_listing(listing, @update_attrs)
      assert %Listing{} = listing
      assert listing.expires_on == ~D[2017-09-17]
      assert listing.state == "XX"
      assert listing.new_construction == false
      assert listing.fios_available == false
      assert listing.tax_rate_code_area == 43
      assert listing.prop_tax_usd == 100
      assert listing.num_skylights == 43
      assert listing.lot_size == "43x43"
      assert listing.attached_garage == false
      assert listing.for_rent == false
      assert listing.zip == "11030-1234"
      assert listing.ext_urls == ["http://www.google.com"]
      assert listing.live_at == ~N[2017-04-17 12:00:00]
      assert listing.city == "some updated city"
      assert listing.num_fireplaces == 43
      assert listing.modern_kitchen_countertops == false
      assert listing.deck == false
      assert listing.for_sale == false
      assert listing.central_air == false
      assert listing.stories == 43
      assert listing.num_half_baths == 43
      assert listing.year_built == 2000
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
      assert listing.realtor_remarks == "some updated realtor_remarks"
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

    test "update_expired_listings/0 sets listing with expires_on in the past to EXP status" do
      listing = listing_fixture()
      assert listing.listing_status_type == :FS
      Realtor.update_expired_listings(0)
      listing = Realtor.get_listing!(listing.id)
      assert listing.listing_status_type == :EXP
    end

    test "saving a listing with a class of Land is successful if beds/baths missing" do
      # this will just blow up if it's invalid
      listing_fixture(%{class_type: :land, num_bedrooms: nil, num_baths: nil, num_half_baths: nil})
    end

    # undelete tests
    test "soft deletes a listing in the database" do
      listing = listing_fixture() |> with_listing_preloads
      user = listing.user
      {:ok, _} = Realtor.delete_listing(listing)

      assert [] = Realtor.list_listings(user)
      assert_raise Ecto.NoResultsError, fn -> Realtor.get_listing!(listing.id) end

      assert {:error, _} = Realtor.create_listing(%{id: listing.id})

      assert_raise Ecto.StaleEntryError, fn ->
        Realtor.update_listing(listing, %{address: "1 Deterministic Road"})
      end

      assert_raise Ecto.StaleEntryError, fn ->
        Realtor.delete_listing(listing)
      end

      assert [soft_deleted_listing] = Realtor.list_deleted_listings()
      assert listings_equal?(listing, soft_deleted_listing)
    end

    # test "soft deletes all listings in the database" do
    #   listing = listing_fixture()
    #   assert {1, nil} = Realtor.delete_all_listings()

    #   assert [] = Realtor.list_listings(listing.user)
    #   assert nil == Realtor.get_listing(listing.id)

    #   assert {:error, _} = Realtor.create_listing(%{id: listing.id})

    #   assert_raise Ecto.StaleEntryError, fn ->
    #     Realtor.update_listing(listing, %{name: "name"})
    #   end

    #   assert_raise Ecto.StaleEntryError, fn ->
    #     Realtor.delete_listing(listing)
    #   end

    #   assert [soft_deleted_listing] = Realtor.list_deleted_listings()
    #   assert listings_equal?(listing, soft_deleted_listing)
    # end

    test "undoes a soft delete on a listing in the database" do
      listing = listing_fixture() |> with_listing_preloads
      user = listing.user
      {:ok, listing} = Realtor.delete_listing(listing)

      assert [] = Realtor.list_listings(user)

      {:ok, listing} = Realtor.undelete_listing(listing)

      assert [new_listing] = Realtor.list_listings(user)
      assert listings_equal?(listing, new_listing)
    end

    test "completely deletes a listing from the database" do
      listing = listing_fixture()
      {:ok, listing} = Realtor.delete_listing(listing)
      {:ok, _} = Realtor.hard_delete_listing(listing)

      assert [] = Realtor.list_deleted_listings()

      listing = listing_fixture()
      {:ok, _} = Realtor.delete_listing(listing)
      assert [_] = Realtor.list_deleted_listings()
    end

    defp listings_equal?(left, right) do
      left.id == right.id and left.address == right.address
    end
  end

  describe "offices" do
    alias Mpnetwork.Realtor.Office

    @valid_attrs %{
      address: "some address",
      city: "some city",
      name: "some name",
      phone: "111-222-3333",
      state: "NY",
      zip: "11050-1234"
    }
    @update_attrs %{
      address: "some updated address",
      city: "some updated city",
      name: "some updated name",
      phone: "333-222-1111",
      state: "CT",
      zip: "11030-4321"
    }
    @invalid_attrs %{address: nil, city: nil, name: nil, phone: nil, state: nil, zip: nil}

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
      assert office.phone == "111-222-3333"
      assert office.state == "NY"
      assert office.zip == "11050-1234"
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
      assert office.phone == "333-222-1111"
      assert office.state == "CT"
      assert office.zip == "11030-4321"
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

  describe "users" do
    alias Mpnetwork.User

    test "list_users/0 returns all users" do
      user = user_fixture()
      retrieved_users = Realtor.list_users()
      [retrieved_user] = retrieved_users
      assert user.email == retrieved_user.email
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Realtor.get_user!(user.id).email == user.email
    end

    test "create_user/1 with valid data creates a user" do
      office = office_fixture()
      valid_attrs = valid_user_attrs(%{office_id: office.id})
      assert {:ok, %User{} = user} = Realtor.create_user(valid_attrs)
      assert user.cell_phone == valid_attrs.cell_phone
      assert user.email == valid_attrs.email
      assert user.name == valid_attrs.name
      assert user.office_id == valid_attrs.office_id
      assert user.office_phone == valid_attrs.office_phone
      assert user.role_id == valid_attrs.role_id
      assert user.url == valid_attrs.url
      assert user.username == valid_attrs.username
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Realtor.create_user(invalid_user_attrs())
    end

    test "update_user/2 with valid data updates the user" do
      office = office_fixture()
      user = user_fixture(%{broker: office})
      assert user.url
      valid_update_attrs = valid_update_user_attrs(%{office_id: office.id})
      assert {:ok, user} = Realtor.update_user(user, valid_update_attrs)
      assert %User{} = user
      assert user.cell_phone == valid_update_attrs.cell_phone
      assert user.name == valid_update_attrs.name
      assert user.office_id == valid_update_attrs.office_id
      assert user.office_phone == valid_update_attrs.office_phone
      assert user.url == valid_update_attrs.url
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Realtor.update_user(user, invalid_user_attrs())
      # because passwords are cleared in changesets...
      from_db = Realtor.get_user!(user.id)
      assert user.name == from_db.name
      assert user.email == from_db.email
      assert user.cell_phone == from_db.cell_phone
      assert user.role_id == from_db.role_id
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Realtor.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Realtor.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Realtor.change_user(user)
    end
  end
end
