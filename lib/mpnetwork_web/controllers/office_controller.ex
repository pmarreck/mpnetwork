defmodule MpnetworkWeb.OfficeController do
  use MpnetworkWeb, :controller

  alias Mpnetwork.Realtor
  alias Mpnetwork.Realtor.Office

  def index(conn, _params) do
    offices = Realtor.list_offices()
    render(conn, "index.html", offices: offices)
  end

  def new(conn, _params) do
    changeset = Realtor.change_office(%Office{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"office" => office_params}) do
    case Realtor.create_office(office_params) do
      {:ok, office} ->
        conn
        |> put_flash(:info, "Office created successfully.")
        |> redirect(to: office_path(conn, :show, office))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    office = Realtor.get_office!(id)
    render(conn, "show.html", office: office)
  end

  def edit(conn, %{"id" => id}) do
    office = Realtor.get_office!(id)
    changeset = Realtor.change_office(office)
    render(conn, "edit.html", office: office, changeset: changeset)
  end

  def update(conn, %{"id" => id, "office" => office_params}) do
    office = Realtor.get_office!(id)

    case Realtor.update_office(office, office_params) do
      {:ok, office} ->
        conn
        |> put_flash(:info, "Office updated successfully.")
        |> redirect(to: office_path(conn, :show, office))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", office: office, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    office = Realtor.get_office!(id)
    {:ok, _office} = Realtor.delete_office(office)

    conn
    |> put_flash(:info, "Office deleted successfully.")
    |> redirect(to: office_path(conn, :index))
  end
end
