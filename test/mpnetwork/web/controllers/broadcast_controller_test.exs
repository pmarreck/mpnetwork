defmodule Mpnetwork.Web.BroadcastControllerTest do
  use Mpnetwork.Web.ConnCase

  alias Mpnetwork.Realtor

  @create_attrs %{body: "some body", title: "some title", user_id: 42}
  @update_attrs %{body: "some updated body", title: "some updated title", user_id: 43}
  @invalid_attrs %{body: nil, title: nil, user_id: nil}

  def fixture(:broadcast) do
    {:ok, broadcast} = Realtor.create_broadcast(@create_attrs)
    broadcast
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, broadcast_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Broadcasts"
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
    assert html_response(conn, 200) =~ "Show Broadcast"
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
    assert html_response(conn, 200) =~ "some updated body"
  end

  test "does not update chosen broadcast and renders errors when data is invalid", %{conn: conn} do
    broadcast = fixture(:broadcast)
    conn = put conn, broadcast_path(conn, :update, broadcast), broadcast: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Broadcast"
  end

  test "deletes chosen broadcast", %{conn: conn} do
    broadcast = fixture(:broadcast)
    conn = delete conn, broadcast_path(conn, :delete, broadcast)
    assert redirected_to(conn) == broadcast_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, broadcast_path(conn, :show, broadcast)
    end
  end
end
