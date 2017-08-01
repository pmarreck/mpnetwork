defmodule MpnetworkWeb.BroadcastControllerTest do

  # use ExUnit.Case, async: true

  use MpnetworkWeb.ConnCase, async: true

  alias Mpnetwork.{Realtor, Repo}
  alias Mpnetwork.Realtor.Broadcast

  import Mpnetwork.Test.Utilities

  @create_attrs %{body: "some broadcast body", title: "some broadcast title", user_id: 1}
  @update_attrs %{body: "some updated broadcast body", title: "some updated broadcast title", user_id: 1}
  @invalid_attrs %{body: nil, title: nil, user_id: 1}

  setup %{conn: conn} do
    user = current_user()
    {:ok, conn: assign(conn, :current_user, user), user: user}
  end

  def fixture(:broadcast) do
    {:ok, broadcast} = Realtor.create_broadcast(@create_attrs)
    broadcast
  end

  test "required login" do
    conn = %Plug.Conn{}
    conn = get conn, broadcast_path(conn, :index)
    assert html_response(conn, 200) =~ "action=\"/sessions\""
    assert conn.resp_body =~ "Email"
    assert conn.resp_body =~ "Password"
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, broadcast_path(conn, :index)
    assert html_response(conn, 200) =~ "Most Recent Broadcasts"
  end

  test "renders form for new broadcasts", %{conn: conn} do
    conn = get conn, broadcast_path(conn, :new)
    assert html_response(conn, 200) =~ "New Broadcast"
  end

  test "creates broadcast and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, broadcast_path(conn, :create), broadcast: @create_attrs

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == broadcast_path(conn, :show, id)

    conn = get conn, broadcast_path(conn, :show, id)
    assert html_response(conn, 200) =~ "Broadcast created successfully"
  end

  test "does not create broadcast and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, broadcast_path(conn, :create), broadcast: @invalid_attrs
    assert html_response(conn, 200) =~ "New Broadcast"
  end

  test "renders form for editing chosen broadcast", %{conn: conn} do
    broadcast = fixture(:broadcast)
    conn = get conn, broadcast_path(conn, :edit, broadcast)
    assert html_response(conn, 200) =~ "Edit Broadcast"
  end

  test "updates chosen broadcast and redirects when data is valid", %{conn: conn} do
    broadcast = fixture(:broadcast)
    conn = put conn, broadcast_path(conn, :update, broadcast), broadcast: @update_attrs
    assert redirected_to(conn) == broadcast_path(conn, :show, broadcast)

    conn = get conn, broadcast_path(conn, :show, broadcast)
    assert html_response(conn, 200) =~ "Broadcast updated successfully"
  end

  test "does not update chosen broadcast and renders errors when data is invalid", %{conn: conn} do
    broadcast = fixture(:broadcast)
    conn = put conn, broadcast_path(conn, :update, broadcast), broadcast: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Broadcast"
  end

  test "deletes chosen broadcast", %{conn: fresh_conn} do
    conn = fresh_conn
    broadcast = fixture(:broadcast)
    conn = delete conn, broadcast_path(conn, :delete, broadcast)
    assert redirected_to(conn) == broadcast_path(conn, :index)
    refute Repo.get(Broadcast, broadcast.id)
    assert_error_sent 404, fn ->
      conn = fresh_conn
      get(conn, broadcast_path(conn, :show, broadcast))
    end
  end
end
