defmodule MpnetworkWeb.UserControllerTest do
  use MpnetworkWeb.ConnCase, async: true

  import Mpnetwork.Test.Support.Utilities

  alias Mpnetwork.Realtor

  setup %{conn: conn} do
    user = user_fixture(%{role_id: 2})
    conn = assign(conn, :current_office, user.broker)
    conn = assign(conn, :current_user, user)
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, user_path(conn, :index))
      assert html_response(conn, 200) =~ "All Users"
    end
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, user_path(conn, :new))
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "create user" do
    test "redirects to show when data is valid", %{conn: original_conn} do
      conn = original_conn
      office = conn.assigns.current_office
      valid_attrs = valid_user_attrs(%{broker: office, office_id: office.id})
      conn = post(conn, user_path(conn, :create), user: valid_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == user_path(conn, :show, id)

      conn = original_conn

      conn = get(conn, user_path(conn, :show, id))
      assert html_response(conn, 200) =~ valid_attrs.name
    end

    test "renders errors when data is invalid", %{conn: conn} do
      office = conn.assigns.current_office

      conn =
        post(
          conn,
          user_path(conn, :create),
          user: invalid_user_attrs(%{broker: office, office_id: office.id})
        )

      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "edit user as admin" do
    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = get(conn, user_path(conn, :edit, user))
      assert html_response(conn, 200) =~ "Editing #{user.name}"
    end
  end

  describe "update user as office admin" do
    test "redirects when data is valid", %{conn: conn, user: user} do
      initial_conn = conn
      updated_fields = valid_update_user_attrs()
      conn = put(conn, user_path(conn, :update, user), user: updated_fields)
      assert redirected_to(conn) == user_path(conn, :show, user)

      conn = initial_conn
      conn = get(conn, user_path(conn, :show, user))
      assert html_response(conn, 200) =~ updated_fields.cell_phone
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, user_path(conn, :update, user), user: invalid_user_attrs())
      assert html_response(conn, 200) =~ "Editing #{user.name}"
    end
  end

  describe "delete user" do
    test "does not delete chosen user if user is not from same office", %{conn: conn, user: _user} do
      realtor_from_another_office = user_fixture(%{role_id: 3})
      conn = delete(conn, user_path(conn, :delete, realtor_from_another_office))
      assert response(conn, 405) =~ "Not allowed"
    end

    test "deletes chosen user if user is from same office", %{conn: conn, user: user} do
      initial_conn = conn

      {:ok, user_from_same_office} =
        Realtor.update_user(user, %{office_id: conn.assigns.current_user.office_id})

      conn = delete(conn, user_path(conn, :delete, user_from_same_office))
      assert redirected_to(conn) == user_path(conn, :index)
      conn = initial_conn

      assert_error_sent(404, fn ->
        get(conn, user_path(conn, :show, user_from_same_office))
      end)
    end

    test "does not 500 when trying to delete a user with listings assigned to them", %{
      conn: conn,
      user: office_admin_user
    } do
      initial_conn = conn
      broker = office_admin_user.broker
      realtor_from_same_office = user_fixture(%{broker: broker, office_id: broker.id, role_id: 3})

      # # some sanity chex
      # 2 = office_admin_user.role_id
      # 3 = realtor_from_same_office.role_id
      # ^broker = realtor_from_same_office.broker
      # ^office_admin_user = conn.assigns.current_user

      _listing = fixture(:listing, realtor_from_same_office)

      # # sanitychex
      # assert listing.user_id == realtor_from_same_office.id
      # assert listing.broker_id == broker.id

      conn = delete(conn, user_path(conn, :delete, realtor_from_same_office))
      refute conn.status == 500
      assert redirected_to(conn) == user_path(conn, :index)
      conn = initial_conn
      # make sure they're gone
      assert_error_sent(404, fn ->
        get(conn, user_path(conn, :show, realtor_from_same_office))
      end)
    end
  end
end
