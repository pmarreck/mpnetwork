defmodule Mpnetwork.Test.Support.Utilities do
  alias Mpnetwork.{User, Realtor, Repo}

  defp random_uniquifying_string do
    trunc(:rand.uniform()*100000000000000000) |> Integer.to_string
  end

  defp rand_between(first, last) do
    trunc(:rand.uniform()*(last - first) + first)
  end

  def valid_user_attrs(attrs \\ %{}) do
    t = Ecto.DateTime.utc
    email = "test#{random_uniquifying_string()}@example.com"
    attrs |> Enum.into(%{
      name: "Realtortest User",
      email: email,
      username: email,
      password: "unit test all the things!",
      password_confirmation: "unit test all the things!",
      cell_phone: "(#{rand_between(100,999)}) #{rand_between(100,999)}-#{rand_between(1000,9999)}",
      office_phone: "(#{rand_between(100,999)}) #{rand_between(100,999)}-#{rand_between(1000,9999)}",
      office_id: 1,
      role_id: 3,
      url: "http://homepage.com",
      email_sig: "",
      last_sign_in_at: t,
      current_sign_in_at: t
    })
  end

  def valid_update_user_attrs(attrs \\ %{}) do
    # email = "test#{random_uniquifying_string()}@example.com"
    attrs |> Enum.into(%{
      name: "Realtortest User#{rand_between(10,99)}",
      # email: email,
      # username: email,
      cell_phone: "(#{rand_between(100,999)}) #{rand_between(100,999)}-#{rand_between(1000,9999)}",
      office_phone: "(#{rand_between(100,999)}) #{rand_between(100,999)}-#{rand_between(1000,9999)}",
      # role_id: 4,
      # current_password: "unit test all the things!",
      # password: "crazytalk!",
      # password_confirmation: "crazytalk!",
      url: "http://homepage-esque.com",
      email_sig: "This is my email signature!",
    })
  end

  def invalid_user_attrs(attrs \\ %{}) do
    attrs |> Enum.into([
      %{url: "http://homepage", cell_phone: "112", office_phone: "321", office_id: 1, role_id: 3, name: "name", email: "invalid_email", username: "invalid_email", password: "gopher", password_confirmation: "gopher"},
      %{url: nil, cell_phone: nil, office_phone: nil, office_id: nil, role_id: nil, name: nil, email: nil, username: nil, password: nil, password_confirmation: nil},
    ] |> Enum.random)
  end

  def valid_office_attrs(attrs \\ %{}) do
    attrs |> Enum.into(%{
      name: "Coach#{trunc :rand.uniform*1000000000000}",
      address: "1 Test Drive #{trunc :rand.uniform*1000000000000}",
      city: "Port Washington",
      state: "NY",
      zip: "11050",
      phone: "(#{rand_between(100,999)}) #{rand_between(100,999)}-#{rand_between(1000,9999)}",
    })
  end

  def valid_broadcast_attrs(attrs \\ %{}) do
    attrs |> Enum.into(%{
      body: "some broadcast body",
      title: "some broadcast title",
    })
  end

  def valid_update_broadcast_attrs(attrs \\ %{}) do
    attrs |> Enum.into(%{
      body: "some updated broadcast body",
      title: "some updated broadcast title",
    })
  end

  def invalid_broadcast_attrs(attrs \\ %{}) do
    attrs |> Enum.into(%{
      body: nil,
      title: nil,
    })
  end

  def user_fixture(attrs \\ %{}) do
    office = if attrs[:broker] do
      attrs[:broker]
    else
      office_fixture()
    end
    attrs = Enum.into(attrs, Enum.into(%{broker: office, office_id: office.id}, valid_user_attrs()))
    {:ok, user} = Realtor.create_user(attrs)
    Repo.preload(user, :broker)
  end

  def office_fixture(attrs \\ %{}) do
    {:ok, office} =
      attrs
      |> Enum.into(valid_office_attrs())
      |> Realtor.create_office()
    office
  end

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
      |> Enum.into(valid_broadcast_attrs())
      |> Realtor.create_broadcast()
    broadcast
  end

  def current_user_stubbed do
    t = Ecto.DateTime.utc
    %User{id: 1, last_sign_in_at: t, current_sign_in_at: t, inserted_at: t, username: "testuser", email: "test_user@tester.com", name: "Test User", role_id: 2}
  end

  def add_current_user(%Plug.Conn{} = conn, user \\ current_user_stubbed()) do
    Plug.Conn.assign(conn, :current_user, user) # returns the new conn
  end

  def i(thing) do
    IO.inspect thing, limit: 100_000, printable_limit: 100_000, pretty: true
  end
end
