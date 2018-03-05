defmodule MpnetworkWeb.BroadcastControllerTest do
  # use ExUnit.Case, async: true

  use MpnetworkWeb.ConnCase, async: true

  alias Mpnetwork.Repo
  alias Mpnetwork.Realtor.Broadcast

  import Mpnetwork.Test.Support.Utilities

  setup %{conn: conn} do
    user = user_fixture()
    conn = assign(conn, :current_office, user.broker)
    conn = assign(conn, :current_user, user)
    {:ok, conn: conn, user: user}
  end

  test "required login" do
    conn = %Plug.Conn{}
    conn = get(conn, broadcast_path(conn, :index))
    assert redirected_to(conn, 302) =~ "/sessions/new"
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get(conn, broadcast_path(conn, :index))
    assert html_response(conn, 200) =~ "Most Recent Broadcasts"
  end

  test "renders form for new broadcasts", %{conn: conn} do
    conn = get(conn, broadcast_path(conn, :new))
    assert html_response(conn, 200) =~ "New Broadcast"
  end

  test "creates broadcast and redirects to show when data is valid", %{conn: initial_conn} do
    conn = initial_conn
    user = conn.assigns.current_user

    conn =
      post(
        conn,
        broadcast_path(conn, :create),
        broadcast: Enum.into(%{user: user, user_id: user.id}, valid_broadcast_attrs())
      )

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == broadcast_path(conn, :show, id)

    conn = initial_conn
    conn = get(conn, broadcast_path(conn, :show, id))
    assert html_response(conn, 200) =~ "some broadcast body"
  end

  test "does not create broadcast and renders errors when data is invalid", %{conn: conn} do
    conn = post(conn, broadcast_path(conn, :create), broadcast: invalid_broadcast_attrs())
    assert html_response(conn, 200) =~ "New Broadcast"
  end

  test "renders form for editing chosen broadcast", %{conn: conn} do
    broadcast = broadcast_fixture(user_id: conn.assigns.current_user.id)
    conn = get(conn, broadcast_path(conn, :edit, broadcast))
    assert html_response(conn, 200) =~ "Edit Broadcast"
  end

  test "updates chosen broadcast and redirects when data is valid", %{conn: initial_conn} do
    conn = initial_conn
    broadcast = broadcast_fixture(user_id: conn.assigns.current_user.id)

    conn =
      put(
        conn,
        broadcast_path(conn, :update, broadcast),
        broadcast: valid_update_broadcast_attrs()
      )

    assert redirected_to(conn) == broadcast_path(conn, :show, broadcast)

    conn = initial_conn
    conn = get(conn, broadcast_path(conn, :show, broadcast))
    assert html_response(conn, 200) =~ "some updated broadcast body"
  end

  test "does not update chosen broadcast and renders errors when data is invalid", %{conn: conn} do
    broadcast = broadcast_fixture(user_id: conn.assigns.current_user.id)

    conn =
      put(conn, broadcast_path(conn, :update, broadcast), broadcast: invalid_broadcast_attrs())

    assert html_response(conn, 200) =~ "Edit Broadcast"
  end

  test "deletes chosen broadcast", %{conn: fresh_conn} do
    conn = fresh_conn
    broadcast = broadcast_fixture(user_id: conn.assigns.current_user.id)
    conn = delete(conn, broadcast_path(conn, :delete, broadcast))
    assert redirected_to(conn) == broadcast_path(conn, :index)
    refute Repo.get(Broadcast, broadcast.id)

    assert_error_sent(404, fn ->
      conn = fresh_conn
      get(conn, broadcast_path(conn, :show, broadcast))
    end)
  end
end
