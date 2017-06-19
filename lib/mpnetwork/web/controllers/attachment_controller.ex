defmodule Mpnetwork.Web.AttachmentController do
  use Mpnetwork.Web, :controller

  alias Mpnetwork.{Listing, Realtor}

  require ExImageInfo
  require Logger

  defp get_cached(id, touch \\ true) do
    id = if is_binary(id), do: String.to_integer(id), else: id
    attachment = case Cachex.get(:attachment_cache, id, fallback: &Listing.get_attachment!/1) do
      {:ok, val}     ->
        Logger.info "Retrieved attachment from app cache: id:#{val.id} '#{val.original_filename}' (#{val.content_type}) listing_id:#{val.listing_id}"
        val
      {:loaded, val} ->
        Logger.info "Retrieved attachment from DB, caching: id:#{val.id} '#{val.original_filename}' (#{val.content_type}) listing_id:#{val.listing_id}"
        val
      {_, val}       -> val
    end
    # Touch it in order to turn LRW policy into an LRU policy
    # but don't bother if we're about to purge it anyway
    # or if you don't want to LRU for some reason (it's LRW without touching)
    if touch do
      Cachex.touch(:attachment_cache, id)
    end
    attachment
  end

  # defp get_cached_and_purge(id) do
  #   attachment = get_cached(id, false)
  #   purge_cached(id)
  #   attachment
  # end

  defp purge_cached(id) do
    id = if is_binary(id), do: String.to_integer(id), else: id
    Logger.info "Purging attachment from cache: id:#{id}"
    {:ok, true} = Cachex.del(:attachment_cache, id)
  end

  defp extract_meta_from_binary_data(binary_data, claimed_content_type) do
    case ExImageInfo.info(binary_data) do
      nil          -> {claimed_content_type, nil, nil}
      {a, b, c, _} -> {a, b, c}
    end
  end

  defp convert_attachment_params_to_attachment_data(attachment_params) do
    # IO.inspect attachment_params
    # %{"data" => %Plug.Upload{content_type: "image/jpeg",
    # filename: "scumbag-steve-if-you-find-the-mirror-of-the-heart-dull-the-rust-has-not-been-cleared-from-its-face.jpg",
    # path: "/var/folders/7w/2lx70htn0nn9rnnq0cmyppfr0000gn/T//plug-1497/multipart-635613-44500-4"},
    # "listing_id" => "2", "primary" => "false"}
    request_data = attachment_params["data"]
    binary_data_loc = request_data.path
    binary_data_orig_filename = request_data.filename
    binary_data = File.read!(binary_data_loc)
    {binary_data_content_type, width_pixels, height_pixels} =
      extract_meta_from_binary_data(binary_data, request_data.content_type)
    Enum.into(%{
      "data" => binary_data,
      "content_type" => binary_data_content_type,
      "original_filename" => binary_data_orig_filename,
      # note that these are all the image types that ExImageInfo recognizes
      "is_image" => case binary_data_content_type do
                      "image/jpeg" -> true
                      "image/gif"  -> true
                      "image/png"  -> true
                      "image/bmp"  -> true
                      "image/psd"  -> true
                      "image/tiff" -> true
                      "image/webp" -> true
                      _            -> false
                    end,
      "sha256_hash" => :crypto.hash(:sha256, binary_data), #note that this is the raw binary, not |> Base.encode16
      "width_pixels" => width_pixels,
      "height_pixels" => height_pixels
    }, attachment_params)
  end

  def index(conn, %{"listing_id" => listing_id} = _params) do
    listing_id = if is_binary(listing_id), do: String.to_integer(listing_id), else: listing_id
    listing = Realtor.get_listing!(listing_id)
    if listing.user_id == current_user(conn).id do
      attachments = Listing.list_attachments(listing_id)
      render(conn, "index.html", attachments: attachments, listing: listing)
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end

  def index(conn, _) do
    # don't render attachment list without a listing_id
    send_resp(conn, 404, "Not Found")
  end

  def new(conn, %{"listing_id" => listing_id} = _params) do
    listing_id = if is_binary(listing_id), do: String.to_integer(listing_id), else: listing_id
    listing = Realtor.get_listing!(listing_id)
    if listing.user_id == current_user(conn).id do
      changeset = Listing.change_attachment(%Mpnetwork.Listing.Attachment{})
      render(conn, "new.html", changeset: changeset, listing: listing)
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end

  def create(conn, %{"attachment" => attachment_params} = params) do
    # only parse attachment data if one is actually posted
    attachment_params = case attachment_params["data"] do
      nil -> attachment_params
      _   -> convert_attachment_params_to_attachment_data(attachment_params)
    end
    listing_id = attachment_params["listing_id"]
    listing_id = if is_binary(listing_id), do: String.to_integer(listing_id), else: listing_id
    listing = Realtor.get_listing!(listing_id)
    if listing.user_id == current_user(conn).id do
      case Listing.create_attachment(attachment_params) do
        {:ok, attachment} ->
          conn
          |> put_flash(:info, "Attachment created successfully.")
          |> redirect(to: attachment_path(conn, :index, listing_id: attachment.listing_id))
        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "new.html", changeset: changeset, listing_id: params["listing_id"])
      end
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end

  # note: this actually delivers the binary data, not an HTML view
  def show(conn, %{"id" => id}) do
    import Plug.Conn
    attachment = get_cached(id)
    # obey the If-None-Match header and send a Not Modified if they're the same
    expected_hash = get_req_header(conn, "if-none-match")
    actual_hash   = Base.encode16(attachment.sha256_hash)
    if Enum.member?(expected_hash, actual_hash) do
      Logger.info "Sending 304 Not Modified for attachment id:#{attachment.id} '#{attachment.original_filename}' (#{attachment.content_type}) listing_id:#{attachment.listing_id}"
      conn
      |> send_resp(304, "")
    else
      Logger.info "Sending attachment id:#{attachment.id} '#{attachment.original_filename}' (#{attachment.content_type}) listing_id:#{attachment.listing_id}"
      conn
      |> put_resp_header("content-type", attachment.content_type)
      |> put_resp_header("content-disposition", "filename=\"#{attachment.original_filename}\"")
      |> put_resp_header("ETag", Base.encode16(attachment.sha256_hash))
      # |> delete_resp_header("set-cookie") # don't need to send cookie data with files
      # Can't seem to delete the set-cookie response header being sent with attachments.
      # Tabling for now. Probably has to do with the secure routes, but I did try
      # piping just the show action through an empty pipeline.
      |> send_resp(200, attachment.data)
    end
  end

  def edit(conn, %{"id" => id}) do
    attachment = get_cached(id)
    listing = Realtor.get_listing!(attachment.listing_id)
    changeset = Listing.change_attachment(attachment)
    render(conn, "edit.html", attachment: attachment, changeset: changeset, listing: listing)
  end

  def update(conn, %{"id" => id, "attachment" => attachment_params}) do
    attachment = get_cached(id, false)
    listing = Realtor.get_listing!(attachment.listing_id)
    if listing.user_id == current_user(conn).id do
      # only parse attachment data if one is actually posted
      attachment_params = case attachment_params["data"] do
        nil -> attachment_params
        _   -> convert_attachment_params_to_attachment_data(attachment_params)
      end
      case Listing.update_attachment(attachment, attachment_params) do
        {:ok, _attachment} ->
          purge_cached(id)
          conn
          |> put_flash(:info, "Attachment updated successfully.")
          |> redirect(to: attachment_path(conn, :index, listing_id: attachment.listing_id))
        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", attachment: attachment, changeset: changeset, listing: listing)
      end
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end

  def delete(conn, %{"id" => id}) do
    attachment = get_cached(id, false)
    listing = Realtor.get_listing!(attachment.listing_id)
    if listing.user_id == current_user(conn).id do
      purge_cached(id)
      {:ok, _attachment} = Listing.delete_attachment(attachment)
      conn
      |> put_flash(:info, "Attachment deleted successfully.")
      |> redirect(to: attachment_path(conn, :index, listing_id: listing.id))
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end
end
