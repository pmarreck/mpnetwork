defmodule MpnetworkWeb.AdminAccessiblePagesTest do
  use MpnetworkWeb.ConnCase, async: true

  import Mpnetwork.Test.Support.Utilities

  # alias Mpnetwork.Realtor

  setup %{conn: conn} do
    user = user_fixture(%{role_id: 3})
    _office_admin = user_fixture(%{role_id: 2})
    _site_admin = user_fixture(%{role_id: 1})
    conn = assign(conn, :current_office, user.broker)
    conn = assign(conn, :current_user, user)
    {:ok, conn: conn, user: user}
  end

  # TBC
end
