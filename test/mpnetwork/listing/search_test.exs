defmodule Mpnetwork.SearchTest do
  use Mpnetwork.DataCase, async: true

  alias Mpnetwork.Realtor

  import Mpnetwork.Test.Support.Utilities

  describe "listing fulltext search" do
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
      for_rent: true,
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
      realtor_remarks: "some remarks",
      parking_spaces: 6,
      description: "some description",
      num_bedrooms: 42,
      high_speed_internet_available: true,
      patio: true,
      address: "1 Fancy Place",
      num_garages: 4,
      num_baths: 5,
      central_vac: true,
      eef_led_lighting: true
    }
    # @update_attrs %{schools: "Man", prop_tax_usd: "100", vill_tax_usd: "100", section_num: "B", block_num: "2", lot_num: "D", live_at: ~N[2017-04-17 12:00:00.000000], expires_on: ~D[2017-09-17], state: "some updated state", new_construction: false, fios_available: false, tax_rate_code_area: 43, num_skylights: 43, lot_size: "43x43", attached_garage: false, for_rent: false, zip: "some updated zip", ext_urls: ["http://www.google.com"], city: "some updated city", num_fireplaces: 43, modern_kitchen_countertops: false, deck: false, for_sale: false, central_air: false, stories: 43, num_half_baths: 43, year_built: 2000, draft: false, pool: false, mls_source_id: 43, security_system: false, sq_ft: 43, studio: false, cellular_coverage_quality: 4, hot_tub: false, basement: false, price_usd: 43, realtor_remarks: "some updated remarks", parking_spaces: 43, description: "some updated description", num_bedrooms: 43, high_speed_internet_available: false, patio: false, address: "some updated address", num_garages: 43, num_baths: 43, central_vac: false, eef_led_lighting: false}
    # @invalid_attrs %{live_at: nil, expires_on: nil, state: nil, new_construction: nil, fios_available: nil, tax_rate_code_area: nil, prop_tax_usd: nil, num_skylights: nil, lot_size: nil, attached_garage: nil, for_rent: nil, zip: nil, ext_urls: nil, city: nil, num_fireplaces: nil, modern_kitchen_countertops: nil, deck: nil, for_sale: nil, central_air: nil, stories: nil, num_half_baths: nil, year_built: nil, draft: nil, pool: nil, mls_source_id: nil, security_system: nil, sq_ft: nil, studio: nil, cellular_coverage_quality: nil, hot_tub: nil, basement: nil, price_usd: nil, realtor_remarks: nil, parking_spaces: nil, description: nil, num_bedrooms: nil, high_speed_internet_available: nil, patio: nil, address: nil, num_garages: nil, num_baths: nil, central_vac: nil, eef_led_lighting: nil}

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

      listing |> Repo.preload([:broker, :user])
    end

    test "listing fulltext search query normalization" do
      assert Realtor.test_normalize_query()
    end

    test "listing query listings with id only" do
      listing = listing_fixture()
      assert {1, [listing], []} == Realtor.query_listings("#{listing.id}", 50, listing.user)
    end

    test "listing query listings with listing status type only" do
      listing = listing_fixture()
      user = listing.user

      assert {:ok, listing} =
               Realtor.update_listing(listing, %{
                 listing_status_type: "UC",
                 uc_on: Date.utc_today()
               })

      assert {1, [listing], []} == Realtor.query_listings("UC", 50, user)
    end

    test "listing query listings with my or mine only" do
      listing = listing_fixture()
      assert {1, [listing], []} == Realtor.query_listings("my", 50, listing.user)
      assert {1, [listing], []} == Realtor.query_listings("mine", 50, listing.user)
    end

    test "listing query listings with 'my drafts'" do
      listing_draft = listing_fixture(%{draft: true})
      other_listing = listing_fixture(%{draft: false, user: listing_draft.user, user_id: listing_draft.user_id, broker: listing_draft.user.broker, broker_id: listing_draft.user.office_id})
      assert {2, [other_listing, listing_draft], []} == Realtor.query_listings("my", 50, listing_draft.user)
      assert {1, [listing_draft], []} == Realtor.query_listings("my drafts", 50, listing_draft.user)
    end

    test "listing query listings with price range only" do
      listing = listing_fixture()
      user = listing.user
      {:ok, listing} = Realtor.update_listing(listing, %{price_usd: 200})
      assert {1, [listing], []} == Realtor.query_listings("150-$250", 50, user)
    end

    test "listing fulltext search" do
      listing = listing_fixture()
      user = listing.user

      user2 =
        user_fixture(%{username: "inigo", email: "inigo@montoya.com", name: "Inigo Montoya"})

      listing2 = listing_fixture(%{user: user2, user_id: user2.id})

      assert {:ok, listing} =
               Realtor.update_listing(listing, %{
                 draft: false,
                 for_sale: true,
                 description: "This is stupendous!"
               })

      assert {:ok, listing2} =
               Realtor.update_listing(listing2, %{
                 draft: false,
                 for_sale: true,
                 description: "inconceivable"
               })

      assert {1, [listing], []} == Realtor.query_listings("stupendous", 50, user)
      # by user's name
      assert {1, [listing], []} == Realtor.query_listings("realtortest", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("stupendous realtortest", 50, user)
      # boolean attribute
      assert {1, [listing], []} == Realtor.query_listings("stupendous sale", 50, user)
      assert {0, [], []} == Realtor.query_listings("stupendous not realtortest", 50, user)

      assert {2, [listing2, listing], []} ==
               Realtor.query_listings("stupendous | inconceivable", 50, user2)
    end

    # room, bedroom, bathroom, fireplace, skylight, garage, family, story
    test "listing bedroom search" do
      listing = listing_fixture(%{num_bedrooms: 5})
      _nonmatching_listing = listing_fixture(%{num_rooms: 18, num_bedrooms: 15})
      bigger_listing = listing_fixture(%{num_bedrooms: 12})
      user = listing.user
      # tests adding of the relevant fulltext-searchable attribute
      assert {1, [listing], []} == Realtor.query_listings("5bed", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5bed|6bed", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5 bed", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5 beds", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5 bedroom", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5 bedrooms", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5-6 beds", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("4-5 beds", 50, user)
      assert {0, [], []} == Realtor.query_listings("3-4 beds", 50, user)
      assert {0, [], []} == Realtor.query_listings("6-8 bedroom", 50, user)
      assert {0, [], []} == Realtor.query_listings("3-4 beds or 6-8 bedroom", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("4-5 beds & 5-7 beds", 50, user)
      assert {1, [bigger_listing], []} == Realtor.query_listings("9-13 bedroom", 50, user)
    end

    test "listing room search" do
      listing = listing_fixture(%{num_rooms: 5, num_bedrooms: 3})
      _nonmatching_listing = listing_fixture(%{num_rooms: 10, num_bedrooms: 10})
      user = listing.user
      assert {1, [listing], []} == Realtor.query_listings("5roo", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5 rooms", 50, user)
      assert {0, [], []} == Realtor.query_listings("6-8 room", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("3-5 rooms", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("3-5 rooms 3-4 bed", 50, user)
      assert {0, [], []} == Realtor.query_listings("3-5 rooms 1-2 bedroom", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("3-5 room or 1-2 beds", 50, user)
    end

    test "listing bathroom search" do
      listing = listing_fixture(%{num_baths: 5, num_bedrooms: 6})
      _nonmatching_listing = listing_fixture(%{num_baths: 10, num_bedrooms: 10})
      user = listing.user
      assert {1, [listing], []} == Realtor.query_listings("5bat", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5 bath", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5 bathroom", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("5 bathrooms", 50, user)
    end

    test "listing fireplace search" do
      listing = listing_fixture(%{num_fireplaces: 2, num_bedrooms: 4})
      _nonmatching_listing = listing_fixture(%{num_fireplaces: 10, num_bedrooms: 10})
      user = listing.user
      assert {1, [listing], []} == Realtor.query_listings("2 fireplaces", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("1-4 fireplace", 50, user)
    end

    test "listing expired search" do
      expired_listing =
        listing_fixture(%{
          live_at: ~N[2017-04-17 12:00:00.000000],
          expires_on: ~D[2017-05-17],
          listing_status_type: "EXP"
        })

      user = expired_listing.user

      _closed_listing =
        listing_fixture(%{
          listing_status_type: "CL",
          closed_on: ~D[2017-05-15],
          closing_price_usd: 1_000_000
        })

      _nonmatching_listing =
        listing_fixture(%{
          listing_status_type: "NEW",
          live_at: Timex.shift(Timex.now(), days: -30),
          expires_on: Timex.today()
        })

      assert {1, [expired_listing], []} == Realtor.query_listings("expired", 50, user)
    end

    test "my/mine in conjunction with other search filter" do
      listing = listing_fixture(%{address: "ALL THINGS BELONG TO ME"})
      user = listing.user
      _nonmatching_listing = listing_fixture()
      assert {1, [listing], []} == Realtor.query_listings("my all things belong to me", 50, user)
      assert {1, [listing], []} == Realtor.query_listings("all things belong to mine", 50, user)
    end

    test "date range search on for-sale (FS/NEW) day" do
      listing = listing_fixture(%{listing_status_type: "NEW", live_at: ~N[2017-01-23 22:50:00.000000]})
      user = listing.user

      assert {1, [listing], []} == Realtor.query_listings("fs: 1/1/2017-2/1/2017", 50, user)

      assert {0, [], ["Invalid start day in Listing Date search range: 11/33/2017"]} ==
               Realtor.query_listings("fs: 11/33/2017-12/1/2017", 50, user)
    end

    test "date range search on under-contract (UC) day" do
      listing = listing_fixture(%{listing_status_type: "UC", uc_on: ~D[2017-12-01]})
      user = listing.user

      assert {1, [listing], []} == Realtor.query_listings("uc: 11/1/2017-12/1/2017", 50, user)

      assert {0, [], ["Invalid start day in Under Contract date search range: 11/33/2017"]} ==
               Realtor.query_listings("uc: 11/33/2017-12/1/2017", 50, user)
    end

    test "date range search on closing (CL) day" do
      listing = listing_fixture(%{listing_status_type: "CL", closing_price_usd: 100000, closed_on: ~D[2017-12-01]})
      user = listing.user

      assert {1, [listing], []} == Realtor.query_listings("cl: 11/1/2017-12/2/2017", 50, user)

      assert {0, [], ["Invalid start day in Closing Date search range: 11/33/2017"]} ==
               Realtor.query_listings("cl: 11/33/2017-12/1/2017", 50, user)
    end

    test "date range search on expired (EXP) day" do
      listing = listing_fixture(%{listing_status_type: "EXP", expires_on: ~D[2017-12-01]})
      user = listing.user

      assert {1, [listing], []} == Realtor.query_listings("EXP: 11/1/2017-12/2/2017", 50, user)

      assert {0, [], ["Invalid start day in Expired Date search range: 11/33/2017"]} ==
               Realtor.query_listings("exp: 11/33/2017-12/1/2017", 50, user)
    end

    test "search on both id # as well as same # in address" do
      listing = listing_fixture()
      user = listing.user

      listing2 =
        listing_fixture(%{address: "#{listing.id} Testy Lane", user: user, user_id: user.id})

      assert {2, [listing2, listing], []} == Realtor.query_listings("#{listing.id}", 50, user)
    end

    # the following should all be considered equivalent:
    # 'dr/drive', 'st/street', 'ln/lane', 'blvd/boulevard', 'ctr/center', 'cir/circle', 'ct/court', 'hts/heights', 'fwy/freeway', 'hwy/highway', 'jct/junction', 'mnr/manor', 'mt/mount', 'pky/parkway', 'pl/place', 'pt/point', 'rd/road', 'sq/square', 'sta/station', 'tpke/turnpike'
    test "search on 'dr/drive' considered equivalent to each other" do
      listing1 = listing_fixture(%{address: "15 Shady Dr"})
      user = listing1.user
      listing2 = listing_fixture(%{address: "25 Shady Drive", user: user, user_id: user.id})
      assert {2, [listing2, listing1], []} == Realtor.query_listings("shady drive", 50, user)
      assert {2, [listing2, listing1], []} == Realtor.query_listings("shady dr", 50, user)
    end

    test "search on 'st/street' considered equivalent to each other (disregarding period)" do
      listing1 = listing_fixture(%{address: "15 Shady St."})
      user = listing1.user
      listing2 = listing_fixture(%{address: "25 Shady Street", user: user, user_id: user.id})
      assert {2, [listing2, listing1], []} == Realtor.query_listings("shady street", 50, user)
      assert {2, [listing2, listing1], []} == Realtor.query_listings("shady st", 50, user)
    end

    test "search on 'ln/lane' considered equivalent to each other" do
      listing1 = listing_fixture(%{address: "15 Shady Ln"})
      user = listing1.user
      listing2 = listing_fixture(%{address: "25 Shady Lane", user: user, user_id: user.id})
      assert {2, [listing2, listing1], []} == Realtor.query_listings("shady lane", 50, user)
      assert {2, [listing2, listing1], []} == Realtor.query_listings("shady ln", 50, user)
    end

    # ...the other less common ones omitted due to using the exact same replacement method

    # Note: This m*****f***er below , this pox on absolute deterministic perfection,
    # is a flagging test BUT ONLY ON STAGING.
    # SOMEtimes it returns {0, [], []} instead of the below expectation (error text).
    # Gotta love those, eh? GRRRR.
    # It's still not a 500, but it's also not what we're looking for.
    # In any event, I'm changing the expectation here to satisfy EITHER condition
    # since all we really want is no 500, and Postgres is being a nondeterministic b**ch.
    # This is less than ideal, obviously.
    # Also, since I'm doing more and more filtering on query text,
    # it's becoming harder and harder to try to trigger a 500... Ironically.
    def no_500_query_result({0, [], []}), do: true

    def no_500_query_result(
          {0, [], ["Something was wrong with the search query: <>?!&^$@*&%^(pajklwer"]}
        ),
        do: true

    def no_500_query_result(_), do: false

    test "malformed search doesn't blow up in a 500 and returns expected error (OR EMPTY ARRAY GRRR)" do
      assert no_500_query_result(
               Realtor.query_listings("<>?!&^$@*&%^(pajklwer", 50, user_fixture())
             )
    end

    test "blank search" do
      listing = listing_fixture()
      user = listing.user
      assert {1, [listing], []} == Realtor.query_listings("", 50, user)
    end
  end
end
