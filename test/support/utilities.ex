defmodule Mpnetwork.Test.Support.Utilities do
  alias Mpnetwork.{User, Realtor}

  def valid_user_attrs do
    t = Ecto.DateTime.utc
    o = office_fixture()
    %{office_id: o.id, email: "test@example#{:rand.uniform(9999999999999)}.com", username: "testuser#{:rand.uniform(9999999999999)}", password: "unit test all the things!", password_confirmation: "unit test all the things!", role_id: 2, last_sign_in_at: t, current_sign_in_at: t}
  end

  def current_user_stubbed do
    t = Ecto.DateTime.utc
    %User{id: 1, last_sign_in_at: t, current_sign_in_at: t, inserted_at: t, username: "testuser", email: "test_user@tester.com", name: "Test User", role_id: 2}
  end

  @valid_office_attrs %{name: "Coach"}
  def office_fixture(attrs \\ %{}) do
    {:ok, office} =
      attrs
      |> Enum.into(@valid_office_attrs)
      |> Realtor.create_office()
    office
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(valid_user_attrs())
      |> Realtor.create_user()
    user
  end

  def add_current_user(%Plug.Conn{} = conn, user \\ current_user_stubbed()) do
    Plug.Conn.assign(conn, :current_user, user) # returns the new conn
  end

  def i(thing) do
    IO.inspect thing, limit: 100_000, printable_limit: 100_000, pretty: true
  end
end
