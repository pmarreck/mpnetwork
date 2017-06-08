defmodule Mpnetwork.Web.BroadcastController do
  use Mpnetwork.Web, :controller

  alias Mpnetwork.Realtor

  def index(conn, _params) do
    broadcasts = Realtor.list_broadcasts()
    render(conn, "index.html", broadcasts: broadcasts)
  end

  def new(conn, _params) do
    changeset = Realtor.change_broadcast(%Mpnetwork.Realtor.Broadcast{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"broadcast" => broadcast_params}) do
    # inject current_user.id
    broadcast_params_with_current_user_id = Enum.into(%{"user_id" => current_user(conn).id}, broadcast_params)
    case Realtor.create_broadcast(broadcast_params_with_current_user_id) do
      {:ok, broadcast} ->
        conn
        |> put_flash(:info, "Broadcast created successfully.")
        |> redirect(to: broadcast_path(conn, :show, broadcast))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    broadcast = Realtor.get_broadcast!(id)
    render(conn, "show.html", broadcast: broadcast)
  end

  def edit(conn, %{"id" => id}) do
    broadcast = Realtor.get_broadcast!(id)
    changeset = Realtor.change_broadcast(broadcast)
    render(conn, "edit.html", broadcast: broadcast, changeset: changeset)
  end

  def update(conn, %{"id" => id, "broadcast" => broadcast_params}) do
    broadcast = Realtor.get_broadcast!(id)

    case Realtor.update_broadcast(broadcast, broadcast_params) do
      {:ok, broadcast} ->
        conn
        |> put_flash(:info, "Broadcast updated successfully.")
        |> redirect(to: broadcast_path(conn, :show, broadcast))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", broadcast: broadcast, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    broadcast = Realtor.get_broadcast!(id)
    {:ok, _broadcast} = Realtor.delete_broadcast(broadcast)

    conn
    |> put_flash(:info, "Broadcast deleted successfully.")
    |> redirect(to: broadcast_path(conn, :index))
  end
end
