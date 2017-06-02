defmodule Mpnetwork.Web.AttachmentControllerTest do
  use Mpnetwork.Web.ConnCase

  alias Mpnetwork.Listing

  @create_attrs %{content_type: "some content_type", data: "some data", height_pixels: 42, original_filename: "some original_filename", primary: true, sha256_hash: "some sha256_hash", width_pixels: 42}
  @update_attrs %{content_type: "some updated content_type", data: "some updated data", height_pixels: 43, original_filename: "some updated original_filename", primary: false, sha256_hash: "some updated sha256_hash", width_pixels: 43}
  @invalid_attrs %{content_type: nil, data: nil, height_pixels: nil, original_filename: nil, primary: nil, sha256_hash: nil, width_pixels: nil}

  def fixture(:attachment) do
    {:ok, attachment} = Listing.create_attachment(@create_attrs)
    attachment
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, attachment_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Attachments"
  end

  test "renders form for new attachments", %{conn: conn} do
    conn = get conn, attachment_path(conn, :new)
    assert html_response(conn, 200) =~ "New Attachment"
  end

  test "creates attachment and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, attachment_path(conn, :create), attachment: @create_attrs

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == attachment_path(conn, :show, id)

    conn = get conn, attachment_path(conn, :show, id)
    assert html_response(conn, 200) =~ "Show Attachment"
  end

  test "does not create attachment and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, attachment_path(conn, :create), attachment: @invalid_attrs
    assert html_response(conn, 200) =~ "New Attachment"
  end

  test "renders form for editing chosen attachment", %{conn: conn} do
    attachment = fixture(:attachment)
    conn = get conn, attachment_path(conn, :edit, attachment)
    assert html_response(conn, 200) =~ "Edit Attachment"
  end

  test "updates chosen attachment and redirects when data is valid", %{conn: conn} do
    attachment = fixture(:attachment)
    conn = put conn, attachment_path(conn, :update, attachment), attachment: @update_attrs
    assert redirected_to(conn) == attachment_path(conn, :show, attachment)

    conn = get conn, attachment_path(conn, :show, attachment)
    assert html_response(conn, 200) =~ "some updated content_type"
  end

  test "does not update chosen attachment and renders errors when data is invalid", %{conn: conn} do
    attachment = fixture(:attachment)
    conn = put conn, attachment_path(conn, :update, attachment), attachment: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Attachment"
  end

  test "deletes chosen attachment", %{conn: conn} do
    attachment = fixture(:attachment)
    conn = delete conn, attachment_path(conn, :delete, attachment)
    assert redirected_to(conn) == attachment_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, attachment_path(conn, :show, attachment)
    end
  end
end
