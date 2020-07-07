defmodule MpnetworkWeb.UserController do
  use MpnetworkWeb, :controller

  alias Mpnetwork.{Realtor, User, Permissions}

  def index(conn, _params) do
    users =
      if Permissions.site_admin?(current_user(conn)) do
        Realtor.list_users()
      else
        Realtor.list_users(conn.assigns.current_office)
      end

    render(conn, "index.html", users: users)
  end

  def locked_users(conn, _params) do
    users =
      if Permissions.site_admin?(current_user(conn)) do
        Realtor.list_locked_users()
      else
        Realtor.list_locked_users(conn.assigns.current_office)
      end

    render(conn, "locked_users.html", users: users)
  end

  def unlock_user(conn, %{"id" => id}) do
    user = Realtor.get_user!(id)

    if Permissions.office_admin_of_office_or_site_admin?(current_user(conn), user.broker) do
      case Realtor.update_user(user, %{"failed_attempts" => 0, "locked_at" => nil}) do
        {:ok, _user} ->
          conn
          |> put_flash(:info, "User unlocked successfully.")
          |> redirect(to: user_path(conn, :locked_users))

        {:error, %Ecto.Changeset{} = _changeset} ->
          conn
          |> put_flash(:error, "There was a problem unlocking this user.")
          |> redirect(to: user_path(conn, :locked_users))
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  # New users should be invited and go through that workflow
  # But admins insisted on being able to create users and manage their passwords, so...

  def new(conn, _params) do
    import Ecto.Changeset, only: [change: 2]

    if Permissions.office_admin_or_site_admin?(current_user(conn)) do
      office = conn.assigns.current_office

      offices =
        if Permissions.office_admin?(current_user(conn)) do
          [office]
        else
          Realtor.list_offices()
        end

      roles = filtered_roles(current_user(conn))
      # default the office to the office of the logged-in user, on new users
      changeset = Realtor.change_user(%User{}) |> change(office_id: office.id)
      render(conn, "new.html", offices: offices, roles: roles, changeset: changeset)
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def create(conn, %{"user" => %{"office_id" => office_id} = user_params}) do
    office = Realtor.get_office!(office_id)

    if Permissions.office_admin_of_office_or_site_admin?(current_user(conn), office) do
      case Realtor.create_user(user_params) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "User created successfully.")
          |> redirect(to: user_path(conn, :show, user))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(
            conn,
            "new.html",
            offices: Realtor.list_offices(),
            roles: filtered_roles(current_user(conn)),
            changeset: changeset
          )
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def show(conn, %{"id" => id}) do
    user = Realtor.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Realtor.get_user!(id)

    if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), user) do
      offices = Realtor.list_offices()
      roles = filtered_roles(current_user(conn))
      changeset = Realtor.change_user(user)
      render(conn, "edit.html", user: user, offices: offices, roles: roles, changeset: changeset)
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Realtor.get_user!(id)

    if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), user) do
      case Realtor.update_user(user, user_params) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "User updated successfully.")
          |> redirect(to: user_path(conn, :show, user))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(
            conn,
            "edit.html",
            user: user,
            offices: Realtor.list_offices(),
            roles: filtered_roles(current_user(conn)),
            changeset: changeset
          )
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Realtor.get_user!(id)

    if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), user) do
      {:ok, _user} = Realtor.delete_user(user)

      conn
      |> put_flash(:info, "User deleted successfully.")
      |> redirect(to: user_path(conn, :index))
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
