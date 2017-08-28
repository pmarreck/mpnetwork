defmodule MpnetworkWeb.OfficeControllerTest do
  use MpnetworkWeb.ConnCase

  alias Mpnetwork.Realtor

  @create_attrs %{address: "some address", city: "some city", name: "some name", phone: "some phone", state: "some state", zip: "some zip"}
  @update_attrs %{address: "some updated address", city: "some updated city", name: "some updated name", phone: "some updated phone", state: "some updated state", zip: "some updated zip"}
  @invalid_attrs %{address: nil, city: nil, name: nil, phone: nil, state: nil, zip: nil}

  def valid_user_attrs, do: %{email: "test@example#{:rand.uniform(9999999999999)}.com", username: "testuser#{:rand.uniform(9999999999999)}", password: "unit test all the things!", password_confirmation: "unit test all the things!", role_id: 2}

  setup %{conn: conn} do
    user = user_fixture()
    {:ok, conn: assign(conn, :current_user, user), user: user}
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(valid_user_attrs())
      |> Realtor.create_user()
    user
  end

  def fixture(:office) do
    {:ok, office} = Realtor.create_office(@create_attrs)
    office
  end

  describe "index" do
    test "lists all offices", %{conn: conn} do
      conn = get conn, office_path(conn, :index)
      assert html_response(conn, 200) =~ "Offices"
    end
  end

  describe "new office" do
    test "renders form", %{conn: conn} do
      conn = get conn, office_path(conn, :new)
      assert html_response(conn, 200) =~ "New Office"
    end
  end

  describe "create office" do
    test "redirects to show when data is valid", %{conn: conn} do
      original_conn = conn
      conn = post conn, office_path(conn, :create), office: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == office_path(conn, :show, id)

      conn = original_conn
      conn = get conn, office_path(conn, :show, id)
      assert html_response(conn, 200) =~ "some name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, office_path(conn, :create), office: @invalid_attrs
      assert html_response(conn, 200) =~ "New Office"
    end
  end

  describe "edit office" do
    setup [:create_office]

    test "renders form for editing chosen office", %{conn: conn, office: office} do
      conn = get conn, office_path(conn, :edit, office)
      assert html_response(conn, 200) =~ "Edit Office"
    end
  end

  describe "update office" do
    setup [:create_office]

    test "redirects when data is valid", %{conn: conn, office: office} do
      original_conn = conn
      conn = put conn, office_path(conn, :update, office), office: @update_attrs
      assert redirected_to(conn) == office_path(conn, :show, office)

      conn = original_conn
      conn = get conn, office_path(conn, :show, office)
      assert html_response(conn, 200) =~ "some updated address"
    end

    test "renders errors when data is invalid", %{conn: conn, office: office} do
      conn = put conn, office_path(conn, :update, office), office: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Office"
    end
  end

  describe "delete office" do
    setup [:create_office]

    test "deletes chosen office", %{conn: conn, office: office} do
      original_conn = conn
      conn = delete conn, office_path(conn, :delete, office)
      assert redirected_to(conn) == office_path(conn, :index)
      conn = original_conn
      assert_error_sent 404, fn ->
        get conn, office_path(conn, :show, office)
      end
    end
  end

  defp create_office(_) do
    office = fixture(:office)
    {:ok, office: office}
  end
end
