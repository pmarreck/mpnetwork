defmodule MpnetworkWeb.AttachmentController do
  use MpnetworkWeb, :controller

  require Mpnetwork.Upload
  alias Mpnetwork.{Listing, Realtor, Upload, Config, Permissions}
  alias Mpnetwork.Listing.{Attachment, AttachmentMetadata}

  require Logger

  # I wrote this function because String.to_integer puked sometimes
  # with certain spurious inputs and caused 500 errors.
  # Should probably be moved to a lib at some point.
  @filter_nondecimal ~r/[^0-9]+/
  defp unerring_string_to_int(bin) when is_binary(bin) do
    bin = Regex.replace(@filter_nondecimal, bin, "")

    case bin do
      "" -> nil
      val -> String.to_integer(val)
    end
  end

  defp unerring_string_to_int(n) when is_float(n), do: round(n)
  defp unerring_string_to_int(n) when is_integer(n), do: n
  defp unerring_string_to_int(_), do: nil

  # match numeric id of length 1-10
  @is_probably_int_pk ~r/^[0-9]{1,10}$/
  # attachments can be gotten by either primary key OR base64-encoded sha256 hash
  defp convert_to_right_identifier(bin) when is_binary(bin) do
    if bin =~ @is_probably_int_pk do
      String.to_integer(bin)
    else
      bin |> Base.url_decode64!()
    end
  end

  defp convert_to_right_identifier(i) when is_integer(i), do: i

  defp get_cached(id, touch \\ true), do: get_cached(id, nil, nil, touch)

  defp get_cached(id, width, height, touch \\ true) do
    id = convert_to_right_identifier(id)
    width = unerring_string_to_int(width)
    height = unerring_string_to_int(height)

    key =
      case {id, width, height} do
        {id, nil, nil} -> id
        {id, w, h} -> {id, w, h}
      end

    attachment =
      case Cachex.get(Config.get(:cache_name), key, fallback: &Listing.get_attachment!/1) do
        {:ok, val} ->
          Logger.info(
            "Retrieved attachment from app cache key #{inspect(key)}: id:#{val.id} '#{
              val.original_filename
            }' (#{val.content_type}) listing_id:#{val.listing_id}"
          )

          val

        {:loaded, val} ->
          Logger.info(
            "Retrieved attachment from DB, caching with key #{inspect(key)}: id:#{val.id} '#{
              val.original_filename
            }' (#{val.content_type}) listing_id:#{val.listing_id}"
          )

          val

        {_, val} ->
          val
      end

    # Touch it in order to turn LRW policy into an LRU policy
    # but don't bother if we're about to purge it anyway
    # or if you don't want to LRU for some reason (it's LRW without touching)
    if touch do
      Cachex.touch(Config.get(:cache_name), key)
    end

    attachment
  end

  # defp get_cached_and_purge(id) do
  #   attachment = get_cached(id, false)
  #   purge_cached(attachment)
  #   attachment
  # end

  defp purge_all_cached_dimensions(%Attachment{} = attachment) do
    id = attachment.id
    sha256_hash = attachment.sha256_hash

    keys_to_delete =
      Config.get(:cache_name)
      |> Cachex.stream!(of: :key)
      |> Enum.filter(fn key ->
        case key do
          {^id, _, _} -> true
          {^sha256_hash, _, _} -> true
          ^id -> true
          ^sha256_hash -> true
          _ -> false
        end
      end)

    Logger.info("Purging these keys from cache: #{inspect(keys_to_delete)}")

    Cachex.transaction(Config.get(:cache_name), keys_to_delete, fn worker ->
      keys_to_delete
      |> Enum.each(fn key ->
        Logger.info("Purging key #{inspect(key)} from cache")
        Cachex.del(worker, key)
      end)
    end)
  end

  defp purge_cached(%Attachment{} = attachment) do
    # id = if is_binary(attachment.id), do: String.to_integer(attachment.id), else: attachment.id
    id = attachment.id
    Logger.info("Purging attachment from cache: id:#{id}")
    {:ok, true} = Cachex.del(Config.get(:cache_name), id)

    if attachment.is_image do
      Logger.info("Seeking out and purging all cached image resizes for id:#{id}")
      purge_all_cached_dimensions(attachment)
    end
  end

  defp convert_attachment_params_to_attachment_data(attachment_params) do
    request_data = Upload.normalize_plug_upload(attachment_params["data"])

    %Upload{
      filename: binary_data_orig_filename,
      binary: binary_data,
      content_type: binary_data_content_type
    } = request_data

    {binary_data_content_type, width_pixels, height_pixels} =
      Upload.extract_meta_from_binary_data(binary_data, binary_data_content_type)

    Enum.into(
      %{
        "data" => binary_data,
        "content_type" => binary_data_content_type,
        "original_filename" => binary_data_orig_filename,
        "is_image" => Upload.is_image?(binary_data_content_type),
        # note that this is the raw binary, not |> Base.encode16
        "sha256_hash" => Upload.sha256_hash(binary_data),
        "width_pixels" => width_pixels,
        "height_pixels" => height_pixels
      },
      attachment_params
    )
  end

  def index(conn, %{"listing_id" => listing_id} = _params) do
    listing_id = if is_binary(listing_id), do: String.to_integer(listing_id), else: listing_id
    listing = Realtor.get_listing!(listing_id)

    if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
      attachments = Listing.list_attachments(listing_id, AttachmentMetadata)
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

    if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
      changeset = Listing.change_attachment(%Attachment{})
      render(conn, "new.html", changeset: changeset, listing: listing)
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end

  def create(conn, %{"attachment" => %{"listing_id" => listing_id} = attachment_params} = _params) do
    # only parse attachment data if one is actually posted
    attachment_params =
      case attachment_params["data"] do
        nil -> attachment_params
        _ -> convert_attachment_params_to_attachment_data(attachment_params)
      end

    listing_id = if is_binary(listing_id), do: String.to_integer(listing_id), else: listing_id
    listing = Realtor.get_listing!(listing_id)

    if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
      case Listing.create_attachment(attachment_params) do
        {:ok, attachment} ->
          conn
          |> put_flash(:info, "Attachment created successfully.")
          |> redirect(to: attachment_path(conn, :index, listing_id: attachment.listing_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "new.html", changeset: changeset, listing: listing, listing_id: listing.id)
      end
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end

  # note: this actually delivers the binary data, not an HTML view
  def show(conn, %{"id" => id, "w" => width, "h" => height}) do
    import Plug.Conn
    attachment = get_cached(id, width, height)
    # obey the If-None-Match header and send a Not Modified if they're the same
    expected_hash = get_req_header(conn, "if-none-match")
    actual_hash = Base.encode16(attachment.sha256_hash)

    if Enum.member?(expected_hash, actual_hash) do
      Logger.info(
        "Sending 304 Not Modified for attachment id:#{attachment.id} w:#{width} h:#{height} '#{
          attachment.original_filename
        }' (#{attachment.content_type}) listing_id:#{attachment.listing_id}"
      )

      conn
      |> send_resp(304, "")
    else
      Logger.info(
        "Sending attachment id:#{attachment.id} w:#{width} h:#{height} '#{
          attachment.original_filename
        }' (#{attachment.content_type}) listing_id:#{attachment.listing_id}"
      )

      # |> delete_resp_header("set-cookie") # don't need to send cookie data with files
      # Can't seem to delete the set-cookie response header being sent with attachments.
      # Tabling for now. Probably has to do with the secure routes, but I did try
      # piping just the show action through an empty pipeline.
      conn
      |> put_resp_header("content-type", attachment.content_type)
      |> put_resp_header("content-disposition", "filename=\"#{attachment.original_filename}\"")
      |> put_resp_header("etag", Base.encode16(attachment.sha256_hash))
      |> send_resp(200, attachment.data)
    end
  end

  # when no width/height provided, default to nil (for pattern match)
  def show(conn, %{"id" => id}), do: show(conn, %{"id" => id, "w" => nil, "h" => nil})

  # this is the attachment show for public MLS-style listings only
  def show_public(conn, %{"id" => id, "w" => _width, "h" => _height} = params) do
    # do not allow id's that look like integer pk's through the public listing path, only base64-encoded sha256 hashes
    if id =~ @is_probably_int_pk do
      send_resp(conn, 404, "Not Found")
    else
      show(conn, params)
    end
  end

  def show_public(conn, %{"id" => id}),
    do: show_public(conn, %{"id" => id, "w" => nil, "h" => nil})

  def edit(conn, %{"id" => id}) do
    attachment = get_cached(id)
    listing = Realtor.get_listing!(attachment.listing_id)

    if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
      changeset = Listing.change_attachment(attachment)
      render(conn, "edit.html", attachment: attachment, changeset: changeset, listing: listing)
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end

  def update(conn, %{"id" => id, "attachment" => attachment_params}) do
    attachment = get_cached(id, false)
    listing = Realtor.get_listing!(attachment.listing_id)

    if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
      # only parse attachment data if one is actually posted
      attachment_params =
        case attachment_params["data"] do
          nil -> attachment_params
          _ -> convert_attachment_params_to_attachment_data(attachment_params)
        end

      case Listing.update_attachment(attachment, attachment_params) do
        {:ok, attachment} ->
          purge_cached(attachment)

          conn
          |> put_flash(:info, "Attachment updated successfully.")
          |> redirect(to: attachment_path(conn, :index, listing_id: attachment.listing_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(
            conn,
            "edit.html",
            attachment: attachment,
            changeset: changeset,
            listing: listing
          )
      end
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end

  def delete(conn, %{"id" => id}) do
    attachment = get_cached(id, false)
    listing = Realtor.get_listing!(attachment.listing_id)

    if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
      # not strictly necessary, would get evicted on next cache cleanup anyway due to disuse
      purge_cached(attachment)
      # but I did it anyway to satisfy the test correctly asserting 404 on a re-retrieval :)
      {:ok, _attachment} = Listing.delete_attachment(attachment)

      conn
      |> put_flash(:info, "Attachment deleted successfully.")
      |> redirect(to: attachment_path(conn, :index, listing_id: listing.id))
    else
      send_resp(conn, 403, "Forbidden: You are not allowed to access these attachments")
    end
  end
end
