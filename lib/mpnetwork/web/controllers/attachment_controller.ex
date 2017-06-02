defmodule Mpnetwork.Web.AttachmentController do
  use Mpnetwork.Web, :controller

  alias Mpnetwork.Listing

  def index(conn, _params) do
    attachments = Listing.list_attachments()
    render(conn, "index.html", attachments: attachments)
  end

  def new(conn, _params) do
    changeset = Listing.change_attachment(%Mpnetwork.Listing.Attachment{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"attachment" => attachment_params}) do
    case Listing.create_attachment(attachment_params) do
      {:ok, attachment} ->
        conn
        |> put_flash(:info, "Attachment created successfully.")
        |> redirect(to: attachment_path(conn, :show, attachment))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    attachment = Listing.get_attachment!(id)
    render(conn, "show.html", attachment: attachment)
  end

  def edit(conn, %{"id" => id}) do
    attachment = Listing.get_attachment!(id)
    changeset = Listing.change_attachment(attachment)
    render(conn, "edit.html", attachment: attachment, changeset: changeset)
  end

  def update(conn, %{"id" => id, "attachment" => attachment_params}) do
    attachment = Listing.get_attachment!(id)

    case Listing.update_attachment(attachment, attachment_params) do
      {:ok, attachment} ->
        conn
        |> put_flash(:info, "Attachment updated successfully.")
        |> redirect(to: attachment_path(conn, :show, attachment))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", attachment: attachment, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    attachment = Listing.get_attachment!(id)
    {:ok, _attachment} = Listing.delete_attachment(attachment)

    conn
    |> put_flash(:info, "Attachment deleted successfully.")
    |> redirect(to: attachment_path(conn, :index))
  end
end
