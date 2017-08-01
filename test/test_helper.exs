ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Mpnetwork.Repo, :manual)

defmodule Mpnetwork.Test.Utilities do
  alias Mpnetwork.User

  def current_user do
    t = Ecto.DateTime.utc
    %User{id: 1, last_sign_in_at: t, confirmed_at: t, current_sign_in_at: t, confirmation_sent_at: t, inserted_at: t, username: "testuser", email: "test_user@tester.com", name: "Test User", role_id: 2}
  end

  def add_current_user(%Plug.Conn{} = conn) do
    Plug.Conn.assign(conn, :current_user, current_user()) # returns the new conn
  end

  def i(thing) do
    IO.inspect thing, limit: 100_000, printable_limit: 100_000, pretty: true
  end
end
