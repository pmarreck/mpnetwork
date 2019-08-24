defmodule Mpnetwork.Test.Support.Utilities do
  alias Mpnetwork.{Listing, User, Realtor, Repo, Upload}

  defp random_uniquifying_string do
    trunc(:rand.uniform() * 100_000_000_000_000_000) |> Integer.to_string()
  end

  defp rand_between(first, last) do
    trunc(:rand.uniform() * (last - first) + first)
  end

  def valid_user_attrs(attrs \\ %{}) do
    t = NaiveDateTime.utc_now()
    email = "test#{random_uniquifying_string()}@example.com"

    %{
      name: "Realtortest User",
      email: email,
      username: email,
      password: "unit test all the things!",
      password_confirmation: "unit test all the things!",
      cell_phone:
        "(#{rand_between(100, 999)}) #{rand_between(100, 999)}-#{rand_between(1000, 9999)}",
      office_phone:
        "(#{rand_between(100, 999)}) #{rand_between(100, 999)}-#{rand_between(1000, 9999)}",
      office_id: 1,
      role_id: 3,
      url: "http://homepage.com",
      email_sig: "",
      last_sign_in_at: t,
      current_sign_in_at: t
    } |> Map.merge(attrs)
  end

  def valid_update_user_attrs(attrs \\ %{}) do
    # email = "test#{random_uniquifying_string()}@example.com"
    %{
      name: "Realtortest User#{rand_between(10, 99)}",
      # email: email,
      # username: email,
      cell_phone:
        "(#{rand_between(100, 999)}) #{rand_between(100, 999)}-#{rand_between(1000, 9999)}",
      office_phone:
        "(#{rand_between(100, 999)}) #{rand_between(100, 999)}-#{rand_between(1000, 9999)}",
      # role_id: 4,
      # current_password: "unit test all the things!",
      # password: "crazytalk!",
      # password_confirmation: "crazytalk!",
      url: "http://homepage-esque.com",
      email_sig: "This is my email signature!"
    } |> Map.merge(attrs)
  end

  def invalid_user_attrs(attrs \\ %{}) do
    [
      %{
        url: "http://homepage",
        cell_phone: "112",
        office_phone: "321",
        office_id: 1,
        role_id: 3,
        name: "name",
        email: "invalid_email",
        username: "invalid_email",
        password: "gopher",
        password_confirmation: "gopher"
      },
      %{
        url: nil,
        cell_phone: nil,
        office_phone: nil,
        office_id: nil,
        role_id: nil,
        name: nil,
        email: nil,
        username: nil,
        password: nil,
        password_confirmation: nil
      }
    ]
    |> Enum.random()
    |> Map.merge(attrs)
  end

  def valid_office_attrs(attrs \\ %{}) do
    %{
      name: "Coach#{trunc(:rand.uniform() * 1_000_000_000_000)}",
      address: "1 Test Drive #{trunc(:rand.uniform() * 1_000_000_000_000)}",
      city: "Port Washington",
      state: "NY",
      zip: "11050",
      phone: "(#{rand_between(100, 999)}) #{rand_between(100, 999)}-#{rand_between(1000, 9999)}"
    } |> Map.merge(attrs)
  end

  def valid_broadcast_attrs(attrs \\ %{}) do
    %{
      body: "some broadcast body",
      title: "some broadcast title"
    } |> Map.merge(attrs)
  end

  def valid_update_broadcast_attrs(attrs \\ %{}) do
    %{
      body: "some updated broadcast body",
      title: "some updated broadcast title"
    } |> Map.merge(attrs)
  end

  def invalid_broadcast_attrs(attrs \\ %{}) do
    attrs
    |> Map.merge(%{
      body: nil,
      title: nil
    })
  end

  def user_fixture(attrs \\ %{}) do
    office =
      if attrs[:broker] do
        attrs[:broker]
      else
        office_fixture()
      end

    attrs =
      valid_user_attrs() |> Map.merge(%{broker: office, office_id: office.id}) |> Map.merge(attrs)

    {:ok, user} = Realtor.create_user(attrs)
    Repo.preload(user, :broker)
  end

  def office_fixture(attrs \\ %{}) do
    {:ok, office} =
      valid_office_attrs()
      |> Map.merge(attrs)
      |> Realtor.create_office()

    office
  end

  def broadcast_fixture(attrs \\ %{}) do
    # first add an associated user if none exists
    attrs =
      unless attrs[:user_id] do
        user = user_fixture()
        Map.merge(attrs, %{user_id: user.id})
      else
        attrs
      end

    {:ok, broadcast} =
      valid_broadcast_attrs()
      |> Map.merge(attrs)
      |> Realtor.create_broadcast()

    broadcast
  end

  def current_user_stubbed do
    t = DateTime.utc_now()

    %User{
      id: 1,
      last_sign_in_at: t,
      current_sign_in_at: t,
      inserted_at: t,
      username: "testuser",
      email: "test_user@tester.com",
      name: "Test User",
      role_id: 2
    }
  end

  @create_listing_attrs %{
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

  # supposedly a png of a red dot
  @test_attachment_binary_data_base64 "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=="
  @test_attachment_binary_data @test_attachment_binary_data_base64 |> Base.decode64!()
  @post_attachment_create_attrs %{
    sha256_hash: Upload.sha256_hash(@test_attachment_binary_data),
    content_type: "image/png",
    data: %Upload{
      content_type: "image/png",
      filename: "test.png",
      binary: @test_attachment_binary_data
    },
    original_filename: "some_original_filename.png",
    is_image: true,
    primary: false
  }
  @attachment_create_attrs Map.merge(@post_attachment_create_attrs, %{data: @test_attachment_binary_data})

  def fixture(:listing, user, attrs) do
    {:ok, listing} =
      Realtor.create_listing(
        @create_listing_attrs |> Map.merge(attrs) |> Map.merge(%{user_id: user.id, user: user, broker_id: user.broker.id, broker: user.broker})
      )

    listing
  end

  def fixture(:listing, user) do
    {:ok, listing} =
      Realtor.create_listing(
        @create_listing_attrs |> Map.merge(%{user_id: user.id, user: user, broker_id: user.broker.id, broker: user.broker})
      )

    listing
  end

  def fixture(:attachment, extra_attrs) do
    {:ok, attachment} =
      Listing.create_attachment(Map.merge(@attachment_create_attrs, extra_attrs))

    attachment
  end

  def add_current_user(%Plug.Conn{} = conn, user \\ current_user_stubbed()) do
    # returns the new conn
    Plug.Conn.assign(conn, :current_user, user)
  end

  def i(thing) do
    IO.inspect(thing, limit: 100_000, printable_limit: 100_000, pretty: true)
  end
end
