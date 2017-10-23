defmodule MpnetworkWeb.UserController do
  use MpnetworkWeb, :controller

  alias Mpnetwork.Realtor
  # alias Mpnetwork.User

  def index(conn, _params) do
    users = Realtor.list_users()
    render(conn, "index.html", users: users)
  end

  # New users should be invited and go through that workflow

  # def new(conn, _params) do
  #   changeset = Realtor.change_user(%User{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  # def create(conn, %{"user" => user_params}) do
  #   case Realtor.create_user(user_params) do
  #     {:ok, user} ->
  #       conn
  #       |> put_flash(:info, "User created successfully.")
  #       |> redirect(to: user_path(conn, :show, user))
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "new.html", changeset: changeset)
  #   end
  # end

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
          |> put_flash(:info, "User updated successfully.")
          |> redirect(to: user_path(conn, :show, user))
        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", user: user, offices: Realtor.list_offices(), roles: filtered_roles(current_user(conn)), changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    user = Realtor.get_user!(id)
    ensure_owner_or_admin(conn, user, fn ->
      {:ok, _user} = Realtor.delete_user(user)

      conn
      |> put_flash(:info, "User deleted successfully.")
      |> redirect(to: user_path(conn, :index))
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
