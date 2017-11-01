defmodule Mpnetwork.SearchTest do
  use Mpnetwork.DataCase

  alias Mpnetwork.Realtor

  import Mpnetwork.Test.Support.Utilities

  describe "listing fulltext search" do

    @valid_attrs %{schools: "Port", prop_tax_usd: "1000", vill_tax_usd: "1000", section_num: "1", block_num: "1", lot_num: "A", visible_on: ~D[2017-04-17], expires_on: ~D[2017-05-17], state: "NY", new_construction: false, fios_available: true, tax_rate_code_area: 42, num_skylights: 42, lot_size: "42x42", attached_garage: true, for_rent: true, zip: "11050", ext_urls: ["http://www.yahoo.com"], city: "New York", num_fireplaces: 3, modern_kitchen_countertops: true, deck: true, for_sale: true, central_air: true, stories: 2, num_half_baths: 2, year_built: 1993, draft: false, pool: true, mls_source_id: 42, security_system: true, sq_ft: 42, studio: false, cellular_coverage_quality: 3, hot_tub: true, basement: true, price_usd: 1000000, remarks: "some remarks", parking_spaces: 6, description: "some description", num_bedrooms: 42, high_speed_internet_available: true, patio: true, address: "1 Fancy Place", num_garages: 4, num_baths: 5, central_vac: true, eef_led_lighting: true}
    # @update_attrs %{schools: "Man", prop_tax_usd: "100", vill_tax_usd: "100", section_num: "B", block_num: "2", lot_num: "D", visible_on: ~D[2017-04-17], expires_on: ~D[2017-09-17], state: "some updated state", new_construction: false, fios_available: false, tax_rate_code_area: 43, num_skylights: 43, lot_size: "43x43", attached_garage: false, for_rent: false, zip: "some updated zip", ext_urls: ["http://www.google.com"], city: "some updated city", num_fireplaces: 43, modern_kitchen_countertops: false, deck: false, for_sale: false, central_air: false, stories: 43, num_half_baths: 43, year_built: 2000, draft: false, pool: false, mls_source_id: 43, security_system: false, sq_ft: 43, studio: false, cellular_coverage_quality: 4, hot_tub: false, basement: false, price_usd: 43, remarks: "some updated remarks", parking_spaces: 43, description: "some updated description", num_bedrooms: 43, high_speed_internet_available: false, patio: false, address: "some updated address", num_garages: 43, num_baths: 43, central_vac: false, eef_led_lighting: false}
    # @invalid_attrs %{visible_on: nil, expires_on: nil, state: nil, new_construction: nil, fios_available: nil, tax_rate_code_area: nil, prop_tax_usd: nil, num_skylights: nil, lot_size: nil, attached_garage: nil, for_rent: nil, zip: nil, ext_urls: nil, city: nil, num_fireplaces: nil, modern_kitchen_countertops: nil, deck: nil, for_sale: nil, central_air: nil, stories: nil, num_half_baths: nil, year_built: nil, draft: nil, pool: nil, mls_source_id: nil, security_system: nil, sq_ft: nil, studio: nil, cellular_coverage_quality: nil, hot_tub: nil, basement: nil, price_usd: nil, remarks: nil, parking_spaces: nil, description: nil, num_bedrooms: nil, high_speed_internet_available: nil, patio: nil, address: nil, num_garages: nil, num_baths: nil, central_vac: nil, eef_led_lighting: nil}

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


    test "listing fulltext search query normalization" do
      assert Realtor.test_normalize_query()
    end

    test "listing query listings with id only" do
      listing = listing_fixture()
      assert [listing] == Realtor.query_listings("#{listing.id}", listing.user)
    end

    test "listing query listings with listing status type only" do
      listing = listing_fixture()
      user = listing.user
      assert {:ok, listing} = Realtor.update_listing(listing, %{listing_status_type: "UC"})
      assert [listing] == Realtor.query_listings("UC", user)
    end

    test "listing query listings with my or mine only" do
      listing = listing_fixture()
      assert [listing] == Realtor.query_listings("my", listing.user)
      assert [listing] == Realtor.query_listings("mine", listing.user)
    end

    test "listing query listings with price range only" do
      listing = listing_fixture()
      user = listing.user
      assert {:ok, listing} = Realtor.update_listing(listing, %{price_usd: 200})
      assert [listing] == Realtor.query_listings("150-$250", user)
    end

    test "listing fulltext search" do
      listing = listing_fixture()
      user = listing.user
      user2 = user_fixture(%{username: "inigo", email: "inigo@montoya.com", name: "Inigo Montoya"})
      listing2 = listing_fixture(user: user2, user_id: user2.id)
      assert {:ok, listing} = Realtor.update_listing(listing, %{draft: false, for_sale: true, description: "This is stupendous!"})
      assert {:ok, listing2} = Realtor.update_listing(listing2, %{draft: false, for_sale: true, description: "inconceivable"})
      assert [listing] == Realtor.query_listings("stupendous", user)
      assert [listing] == Realtor.query_listings("realtortest", user) # by user's name
      assert [listing] == Realtor.query_listings("stupendous realtortest", user)
      assert [listing] == Realtor.query_listings("stupendous sale", user) # boolean attribute
      assert [] == Realtor.query_listings("stupendous not realtortest", user)
      assert [listing2, listing] == Realtor.query_listings("stupendous | inconceivable", user2)
    end

    # room, bedroom, bathroom, fireplace, skylight, garage, family, story
    test "listing bedroom search" do
      listing = listing_fixture(num_bedrooms: 5)
      _nonmatching_listing = listing_fixture(num_rooms: 18, num_bedrooms: 15)
      bigger_listing = listing_fixture(num_bedrooms: 12)
      user = listing.user
      # tests adding of the relevant fulltext-searchable attribute
      assert [listing] == Realtor.query_listings("5bed", user)
      assert [listing] == Realtor.query_listings("5bed|6bed", user)
      assert [listing] == Realtor.query_listings("5 bed", user)
      assert [listing] == Realtor.query_listings("5 beds", user)
      assert [listing] == Realtor.query_listings("5 bedroom", user)
      assert [listing] == Realtor.query_listings("5 bedrooms", user)
      assert [listing] == Realtor.query_listings("5-6 beds", user)
      assert [listing] == Realtor.query_listings("4-5 beds", user)
      assert [] == Realtor.query_listings("3-4 beds", user)
      assert [] == Realtor.query_listings("6-8 bedroom", user)
      assert [] == Realtor.query_listings("3-4 beds or 6-8 bedroom", user)
      assert [listing] == Realtor.query_listings("4-5 beds & 5-7 beds", user)
      assert [bigger_listing] == Realtor.query_listings("9-13 bedroom", user)
    end

    test "listing room search" do
      listing = listing_fixture(num_rooms: 5, num_bedrooms: 3)
      _nonmatching_listing = listing_fixture(num_rooms: 10, num_bedrooms: 10)
      user = listing.user
      assert [listing] == Realtor.query_listings("5roo", user)
      assert [listing] == Realtor.query_listings("5 rooms", user)
      assert [] == Realtor.query_listings("6-8 room", user)
      assert [listing] == Realtor.query_listings("3-5 rooms", user)
      assert [listing] == Realtor.query_listings("3-5 rooms 3-4 bed", user)
      assert [] == Realtor.query_listings("3-5 rooms 1-2 bedroom", user)
      assert [listing] == Realtor.query_listings("3-5 room or 1-2 beds", user)
    end

    test "listing bathroom search" do
      listing = listing_fixture(num_baths: 5, num_bedrooms: 6)
      _nonmatching_listing = listing_fixture(num_baths: 10, num_bedrooms: 10)
      user = listing.user
      assert [listing] == Realtor.query_listings("5bat", user)
      assert [listing] == Realtor.query_listings("5 bath", user)
      assert [listing] == Realtor.query_listings("5 bathroom", user)
      assert [listing] == Realtor.query_listings("5 bathrooms", user)
    end

    test "listing fireplace search" do
      listing = listing_fixture(num_fireplaces: 2, num_bedrooms: 4)
      _nonmatching_listing = listing_fixture(num_fireplaces: 10, num_bedrooms: 10)
      user = listing.user
      assert [listing] == Realtor.query_listings("2 fireplaces", user)
      assert [listing] == Realtor.query_listings("1-4 fireplace", user)
    end

    test "listing expired search" do
      expired_listing = listing_fixture(visible_on: ~D[2017-04-17], expires_on: ~D[2017-05-17])
      user = expired_listing.user
      closed_listing = listing_fixture(listing_status_type: "CL")
      _nonmatching_listing = listing_fixture(listing_status_type: "NEW", visible_on: Timex.shift(Timex.today, days: -30), expires_on: Timex.today)
      assert [closed_listing, expired_listing] == Realtor.query_listings("expired", user)
    end

    test "my/mine in conjunction with other search filter" do
      listing = listing_fixture(address: "ALL THINGS BELONG TO ME")
      user = listing.user
      _nonmatching_listing = listing_fixture()
      assert [listing] == Realtor.query_listings("my all things belong to me", user)
      assert [listing] == Realtor.query_listings("all things belong to mine", user)
    end

  end

end
