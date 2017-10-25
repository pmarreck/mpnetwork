defmodule MpnetworkWeb.ProfileController do
  use MpnetworkWeb, :controller

  alias Mpnetwork.Realtor
  # alias Mpnetwork.User

  import MpnetworkWeb.GlobalHelpers, only: [is_admin: 1]

  def show(conn, %{"id" => id}) do
    user = Realtor.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Realtor.get_user!(id)
    ensure_owner_or_admin(conn, user, fn ->
      offices = Realtor.list_offices()
      roles = filtered_roles(current_user(conn))
      changeset = Realtor.change_user(user)
      render(conn, "edit.html", user: user, offices: offices, roles: roles, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Realtor.get_user!(id)

    ensure_owner_or_admin(conn, user, fn ->
      case Realtor.update_user(user, user_params) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "Profile updated successfully.")
          |> redirect(to: profile_path(conn, :show, user))
        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", user: user, offices: Realtor.list_offices(), roles: filtered_roles(current_user(conn)), changeset: changeset)
      end
    end)
  end

  defp ensure_owner_or_admin(conn, resource, lambda) do
    u = current_user(conn)
    oid = resource.id
    admin = u.role_id < 3
    if u.id == oid || admin do
      lambda.()
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  defp filtered_roles(current_user) do
    import MpnetworkWeb.GlobalHelpers, only: [roles_with_index: 0]
    roles_with_index()
    |> Enum.filter(fn {_role, role_id} -> role_id >= current_user.role_id end)
  end

end
