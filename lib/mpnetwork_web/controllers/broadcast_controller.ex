defmodule MpnetworkWeb.BroadcastController do
  use MpnetworkWeb, :controller

  alias Mpnetwork.{Realtor, Permissions}

  @index_max 20

  def index(conn, _params) do
    broadcasts = Realtor.list_latest_broadcasts(@index_max)
    render(conn, "index.html", broadcasts: broadcasts, length: @index_max)
  end

  def new(conn, _params) do
    if !Permissions.read_only?(current_user(conn)) do
      changeset = Realtor.change_broadcast(%Realtor.Broadcast{})
      render(conn, "new.html", changeset: changeset)
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def create(conn, %{"broadcast" => broadcast_params}) do
    # inject current_user.id
    if !Permissions.read_only?(current_user(conn)) do
      broadcast_params_with_current_user_id =
        Enum.into(%{"user_id" => current_user(conn).id}, broadcast_params)

      case Realtor.create_broadcast(broadcast_params_with_current_user_id) do
        {:ok, broadcast} ->
          conn
          |> put_flash(:info, "Broadcast created successfully.")
          |> redirect(to: Routes.broadcast_path(conn, :show, broadcast))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "new.html", changeset: changeset)
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def show(conn, %{"id" => id}) do
    broadcast = Realtor.get_broadcast_with_user!(id)
    render(conn, "show.html", broadcast: broadcast)
  end

  def edit(conn, %{"id" => id}) do
    if !Permissions.read_only?(current_user(conn)) do
      broadcast = Realtor.get_broadcast!(id)

      if current_user(conn).id == broadcast.user_id || current_user(conn).role_id < 3 do
        changeset = Realtor.change_broadcast(broadcast)
        render(conn, "edit.html", broadcast: broadcast, changeset: changeset)
      else
        send_resp(conn, 405, "Not allowed")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def update(conn, %{"id" => id, "broadcast" => broadcast_params}) do
    if !Permissions.read_only?(current_user(conn)) do
      broadcast = Realtor.get_broadcast!(id)
      # inject current_user.id
      broadcast_params_with_current_user_id =
        Enum.into(%{"user_id" => current_user(conn).id}, broadcast_params)

      if current_user(conn).id == broadcast.user_id || current_user(conn).role_id < 3 do
        case Realtor.update_broadcast(broadcast, broadcast_params_with_current_user_id) do
          {:ok, broadcast} ->
            conn
            |> put_flash(:info, "Broadcast updated successfully.")
            |> redirect(to: Routes.broadcast_path(conn, :show, broadcast))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "edit.html", broadcast: broadcast, changeset: changeset)
        end
      else
        send_resp(conn, 405, "Not allowed")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def delete(conn, %{"id" => id}) do
    if !Permissions.read_only?(current_user(conn)) do
      broadcast = Realtor.get_broadcast!(id)

      if current_user(conn).id == broadcast.user_id || current_user(conn).role_id < 2 do
        {:ok, _broadcast} = Realtor.delete_broadcast(broadcast)

        conn
        |> put_flash(:info, "Broadcast deleted successfully.")
        |> redirect(to: Routes.broadcast_path(conn, :index))
      else
        send_resp(conn, 405, "Not allowed")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end
end
