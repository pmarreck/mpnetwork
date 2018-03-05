defmodule MpnetworkWeb.OfficeControllerTest do
  use MpnetworkWeb.ConnCase, async: true

  alias Mpnetwork.Realtor

  @update_attrs %{
    address: "some updated address",
    city: "some updated city",
    name: "some updated name",
    phone: "111-222-3333",
    state: "CT",
    zip: "11030-1234"
  }
  @invalid_attrs %{address: nil, city: nil, name: nil, phone: nil, state: nil, zip: nil}

  def valid_user_attrs do
    t = NaiveDateTime.utc_now()
    o = fixture(:office)

    %{
      office_id: o.id,
      email: "test@example#{:rand.uniform(9_999_999_999_999)}.com",
      username: "testuser#{:rand.uniform(9_999_999_999_999)}",
      password: "unit test all the things!",
      password_confirmation: "unit test all the things!",
      role_id: 2,
      last_sign_in_at: t,
      current_sign_in_at: t
    }
  end

  def create_attrs do
    %{
      address: "some address",
      city: "some city",
      name: "some name #{:rand.uniform(9_999_999_999_999)}",
      phone: "222-333-4444",
      state: "NY",
      zip: "11050-4321"
    }
  end

  setup %{conn: conn} do
    user = user_fixture(%{role_id: 1})
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
    {:ok, office} = Realtor.create_office(create_attrs())
    office
  end

  describe "index" do
    test "lists all offices", %{conn: conn} do
      conn = get(conn, office_path(conn, :index))
      assert html_response(conn, 200) =~ "Offices"
    end
  end

  describe "new office" do
    test "renders form", %{conn: conn} do
      conn = get(conn, office_path(conn, :new))
      assert html_response(conn, 200) =~ "New Office"
    end
  end

  describe "create office" do
    test "redirects to show when data is valid", %{conn: conn} do
      original_conn = conn
      conn = post(conn, office_path(conn, :create), office: create_attrs())

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == office_path(conn, :show, id)

      conn = original_conn
      conn = get(conn, office_path(conn, :show, id))
      assert html_response(conn, 200) =~ "some name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, office_path(conn, :create), office: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Office"
    end
  end

  describe "edit office" do
    setup [:create_office]

    test "renders form for editing chosen office", %{conn: conn, office: office} do
      conn = get(conn, office_path(conn, :edit, office))
      assert html_response(conn, 200) =~ "Edit Office"
    end
  end

  describe "update office" do
    setup [:create_office]

    test "redirects when data is valid", %{conn: conn, office: office} do
      original_conn = conn
      conn = put(conn, office_path(conn, :update, office), office: @update_attrs)
      assert redirected_to(conn) == office_path(conn, :show, office)

      conn = original_conn
      conn = get(conn, office_path(conn, :show, office))
      assert html_response(conn, 200) =~ "some updated address"
    end

    test "renders errors when data is invalid", %{conn: conn, office: office} do
      conn = put(conn, office_path(conn, :update, office), office: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Office"
    end
  end

  describe "delete office" do
    setup [:create_office]

    test "deletes chosen office", %{conn: conn, office: office} do
      original_conn = conn
      conn = delete(conn, office_path(conn, :delete, office))
      assert redirected_to(conn) == office_path(conn, :index)
      conn = original_conn

      assert_error_sent(404, fn ->
        get(conn, office_path(conn, :show, office))
      end)
    end
  end

  defp create_office(_) do
    office = fixture(:office)
    {:ok, office: office}
  end
end
