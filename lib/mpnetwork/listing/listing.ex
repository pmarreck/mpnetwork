defmodule Mpnetwork.Listing do
  @moduledoc """
  The boundary for the Listing system.
  """

  import Ecto.Query, warn: false
  alias Mpnetwork.Repo
  alias Briefly, as: Temp
  # alias Mogrify, as: SlowImage
  # use Mogrify.Options # this is ugly, want to remove it someday EDIT: I'VE ACHIEVED THE DREAM, IT'S FINALLY FUCKING GONE
  # require Elxvips
  # alias Elxvips, as: FastImage
  # alias Elxvips.ImageBytes
  # require Vix
  alias Vix.Vips.Image
  alias Vix.Vips.Operation, as: ImageOperation
  require Mpnetwork.Upload
  alias Mpnetwork.Upload

  alias Mpnetwork.Listing.{Attachment, AttachmentMetadata}

  # @doc """
  # Returns the list of attachments.

  # ## Examples

  #     iex> list_attachments()
  #     [%Attachment{}, ...]

  # """
  # def list_attachments do
  #   Repo.all(Attachment)
  # end

  @doc """
  Returns the list of attachments for a given listing_id.

  ## Examples

      iex> list_attachments(1)
      [%Attachment{}, ...]

  """
  def list_attachments(listing_id, attachment_schema \\ Attachment)

  def list_attachments(listing_id, attachment_schema) when attachment_schema in [Attachment, AttachmentMetadata] do
    Repo.all(
      from(
        attachment in attachment_schema,
        where: attachment.listing_id == ^listing_id,
        order_by: [
          desc: attachment.is_image,
          desc: attachment.primary,
          asc: attachment.inserted_at
        ]
      )
    )
  end

  @doc """
  Returns the primary image for a given listing_id.

  ## Examples

      iex> find_primary_image(1)
      [%Attachment{}, ...]

  """
  def find_primary_image(listing_id, attachment_schema \\ Attachment)

  def find_primary_image(listing_id, attachment_schema) when attachment_schema in [Attachment, AttachmentMetadata] do
    Repo.one(
      from(
        attachment in attachment_schema,
        where: attachment.listing_id == ^listing_id,
        where: attachment.is_image == true,
        order_by: [desc: attachment.primary],
        limit: 1
      )
    )
  end

  @doc """
  Returns a map of listing_ids to the primary image for a given listing.
  TODO: rewrite this to make the DB do the work instead of requerying.

  ## Examples

      iex> primary_images_for_listings(1)
      %{1 => %Attachment{}, ...}

  """
  def primary_images_for_listings(listings, attachment_schema \\ Attachment) do
    Enum.reduce(listings, %{}, fn listing, map ->
      %{listing.id => find_primary_image(listing.id, attachment_schema)}
      |> Enum.into(map)
    end)
  end

  defp do_rotate_attachment(_degrees, nil), do: nil
  defp do_rotate_attachment(degrees, attachment) when degrees in [-90, 90] do

    # get extension from mimetype
    extname = "." <> Upload.map_img_content_type_to_file_ext(attachment.content_type)
    # write temp file to disk
    {:ok, in_tempfile} = Temp.create()
    {:ok, out_tempfile} = Temp.create(extname: extname)
    # should close file handle
    File.write!(in_tempfile, attachment.data)
    # do rotation on disk
    {:ok, im} = Image.new_from_file(in_tempfile)
# import Mpnetwork.Utils.Debugging
# i(Vix.Nif.nif_vips_operation_list()) # full output:
# ["globalbalance", "match", "matrixinvert", "mosaic1", "mosaic", "merge",
#  "draw_smudge", "draw_image", "draw_flood", "draw_circle", "draw_line",
#  "draw_mask", "draw_rect", "fill_nearest", "labelregions", "countlines", "rank",
#  "morph", "phasecor", "spectrum", "freqmult", "invfft", "fwfft", "sobel",
#  "canny", "gaussblur", "sharpen", "spcor", "fastcor", "convasep", "convsep",
#  "compass", "convi", "convf", "conva", "conv", "hist_entropy",
#  "hist_ismonotonic", "hist_local", "hist_plot", "hist_equal", "hist_norm",
#  "hist_match", "hist_cum", "stdif", "percent", "case", "maplut", "profile_load",
#  "XYZ2CMYK", "CMYK2XYZ", "scRGB2sRGB", "scRGB2BW", "sRGB2scRGB", "dECMC",
#  "dE00", "dE76", "icc_transform", "icc_export", "icc_import", "HSV2sRGB",
#  "sRGB2HSV", "LabQ2sRGB", "float2rad", "rad2float", "Lab2LabS", "LabS2Lab",
#  "LabS2LabQ", "LabQ2LabS", "Lab2LabQ", "LabQ2Lab", "XYZ2scRGB", "scRGB2XYZ",
#  "Yxy2XYZ", "XYZ2Yxy", "CMC2LCh", "LCh2CMC", "LCh2Lab", "Lab2LCh", "XYZ2Lab",
#  "Lab2XYZ", "colourspace", "resize", "rotate", "similarity", "affine",
#  "quadratic", "reduce", "reducev", "reduceh", "shrinkv", "shrinkh", "shrink",
#  "mapim", "thumbnail_source", "thumbnail_image", "thumbnail_buffer",
#  "thumbnail", "switch", "perlin", "worley", "fractsurf", "identity", "tonelut",
#  "invertlut", "buildlut", "mask_fractal", "mask_gaussian_band",
#  "mask_gaussian_ring", "mask_gaussian", "mask_butterworth_band",
#  "mask_butterworth_ring", "mask_butterworth", "mask_ideal_band",
#  "mask_ideal_ring", "mask_ideal", "sines", "zone", "grey", "eye", "logmat",
#  "gaussmat", "xyz", "text", "gaussnoise", "black", "composite2", "composite",
#  "gamma", "falsecolour", "byteswap", "msb", "subsample", "zoom", "wrap",
#  "scale", "transpose3d", "grid", "unpremultiply", "premultiply", "flatten",
#  "bandunfold", "bandfold", "recomb", "ifthenelse", "autorot", "rot45", "rot",
#  "cast", "replicate", "bandbool", "bandmean", "bandrank", "bandjoin_const",
#  "bandjoin", "extract_band", "smartcrop", "extract_area", "extract_area",
#  "arrayjoin", "join", "insert", "flip", "gravity", "embed", "cache",
#  "sequential", "linecache", "tilecache", "copy", "find_trim", "getpoint",
#  "measure", "profile", "project", "hough_circle", "hough_line",
#  "hist_find_indexed", "hist_find_ndim", "hist_find", "stats", "deviate", "max",
#  "min", "avg", "complexget", "complex", "math2_const", "boolean_const",
#  "remainder_const", "relational_const", "round", "sign", "abs", "math",
#  "linear", "invert", "sum", "complexform", "complex2", "math2", "boolean",
#  "remainder", "relational", "divide", "multiply", "subtract", "add", "system"]

    # note: left mogrify code in here in case it's ever needed again
    # rotated_image =
    #   SlowImage.open(tempfile)
    #   |> SlowImage.add_option(option_rotate("#{degrees}"))
    #   # |> SlowImage.add_option(option_define("png:color-type=3"))
    #   |> SlowImage.quality("85")
    #   |> SlowImage.save
    degrees_vips = case degrees do
      90 -> :VIPS_ANGLE_D90
      -90 -> :VIPS_ANGLE_D270
    end
    {:ok, new_im} = ImageOperation.rot(im, degrees_vips)
    :ok = Image.write_to_file(new_im, out_tempfile)

    # read new file off disk into memory
    # rotated_image_data = File.read!(rotated_image.path)
    rotated_image_data = File.read!(out_tempfile)

    # parse new file's dimensions
    {binary_data_content_type, width_pixels, height_pixels} =
      Upload.extract_meta_from_binary_data(rotated_image_data, attachment.content_type)

    new_sha256_hash = :crypto.hash(:sha256, rotated_image_data)

    # return the modified attachment changeset (not saved yet)
    attachment
    |> Attachment.changeset(%{
      width_pixels: width_pixels,
      height_pixels: height_pixels,
      content_type: binary_data_content_type,
      sha256_hash: new_sha256_hash,
      data: rotated_image_data,
      inserted_at: attachment.inserted_at,
      updated_at: Timex.now("America/New_York")
    })
  end

  def rotate_attachment_left_90!(nil), do: nil
  def rotate_attachment_left_90!(%Attachment{} = attachment) do
    do_rotate_attachment(-90, attachment)
  end

  def rotate_attachment_left_90!(id) when is_integer(id) or is_binary(id) do
    # retrieve image from cache
    get_attachment!(id)
    |> rotate_attachment_left_90!
  end

  def rotate_attachment_right_90!(%Attachment{} = attachment) do
    do_rotate_attachment(90, attachment)
  end

  def rotate_attachment_right_90!(nil), do: nil
  def rotate_attachment_right_90!(id) when is_integer(id) or is_binary(id) do
    # retrieve image from cache
    get_attachment!(id)
    |> rotate_attachment_right_90!
  end

  @doc """
  Gets a single attachment at a given width and height.

  Raises `Ecto.NoResultsError` if the Attachment does not exist.

  ## Examples

      iex> get_attachment!({123, 1, 1})
      %Attachment{}

      iex> get_attachment!({456, 1, 1})
      ** (Ecto.NoResultsError)

  """
  def get_attachment!({id, width, height}) when is_integer(id) do
    # first we will get the original attachment from the DB, filtering on images-only
    # Repo.get!(Attachment, id)
    Repo.one!(
      from(
        attachment in Attachment,
        where: attachment.id == ^id,
        where: attachment.is_image == true,
        limit: 1
      )
    )
    |> do_get_attachment(width, height)
  end

  def get_attachment!({id, width, height}) when is_binary(id) do
    # first we will get the original attachment from the DB by SHA256
    handle_same_hash_for_multiple_possible_attachments(id)
    |> do_get_attachment(width, height)
  end

  # @filter_nonbase64ish ~r/[^0-9A-Za-z\+\/\=\-%_]+/
  # defp clean_hash(hash) when is_binary(hash) do
  #   # remove trailing double quotes, spaces, etc
  #   Regex.replace(@filter_nonbase64ish, hash, "")
  # end

  # Note that the hash here is a binary hash, not a base64-encoded hash, at this point
  defp handle_same_hash_for_multiple_possible_attachments(hash, attachment_schema \\ Attachment) when is_binary(hash) do
    # Note that duplicate image uploads are allowed currently, in which the SHA will be the same
    # sooooo... we select the most recently inserted one.
    # What could possibly go wrong?!?!
    # I mean, this will work... MOST of the time.
    # Until you try to rotate an old image that has a newer duplicate.
    # Need to still handle that case.
    case Repo.all(
      from(
        attachment in attachment_schema,
        where: attachment.sha256_hash == ^hash,
        order_by: [desc: attachment.inserted_at],
        limit: 1
      )
    ) do
      [] -> nil
      [first | _rest] -> first
    end
  end

  defp do_get_attachment(nil, _width, _height), do: nil
  defp do_get_attachment(attachment, width, height) when is_integer(width) and is_integer(height) do
    # We need to rate-limit mogrify to avoid server memory spikes
    case ExRated.inspect_bucket(
           :mogrify_rate_limiter,
           Application.get_env(:ex_rated, :bucket_time),
           Application.get_env(:ex_rated, :bucket_limit)
         ) do
      {_count, count_remaining, _ms_to_next_bucket, _created_at, _updated_at}
      when count_remaining > 0 ->
        # then we will write its binary data to a local tempfile
        # {:ok, path} = Temp.create()
        # should close file automatically
        # File.write!(path, attachment.data)
        # then we will resize it
        # image = Image.new_from_file(path)

        # image = SlowImage.open(path) |> SlowImage.resize_to_limit("#{width}x#{height}") |> SlowImage.save

        # {:ok, %ImageBytes{bytes: resized_image_data}} = FastImage.from_bytes(attachment.data) |> FastImage.resize(width: width, height: height) |> FastImage.to_bytes()

        # get extension from mimetype
        extname = "." <> Upload.map_img_content_type_to_file_ext(attachment.content_type)
        # write temp file to disk
        {:ok, in_tempfile} = Temp.create()
        {:ok, out_tempfile} = Temp.create(extname: extname)
        # should close file handle
        File.write!(in_tempfile, attachment.data)

        original_width = attachment.width_pixels
        original_height = attachment.height_pixels
        largest_dimension = if original_width >= original_height, do: :width, else: :height

        scale = case largest_dimension do
          :width -> width / original_width # these result in floats even if ints, according to iex
          :height -> height / original_height
        end

        # never increase size, let the browser do that (probably bicubic interpolation)
        scale = if scale > 1.0, do: 1.0, else: scale

        # do resize on disk
        {:ok, im} = Image.new_from_file(in_tempfile)

        {:ok, new_im} = ImageOperation.resize(im, scale)

        :ok = Image.write_to_file(new_im, out_tempfile)

        # read new file off disk into memory
        # resized_image_data = File.read!(rotated_image.path)
        resized_image_data = File.read!(out_tempfile)

        new_sha256_hash = :crypto.hash(:sha256, resized_image_data)

        # resized_image_data = :binary.list_to_bin(resized_image_data)
        # then we will reread the new file's binary data
        # resized_image_data = File.read!(image.path)
        # then we will parse the new file's actual dimensions
        {binary_data_content_type, width_pixels, height_pixels} =
          Upload.extract_meta_from_binary_data!(resized_image_data)

        # clean up the non-tempfile
        # File.rm!(image.path)
        # then we will return this (which currently gets stored in the app cache)
        # applies WITHOUT saving, FYI! DO NOT SAVE THIS :O
        attachment
        |> Attachment.changeset(%{
          width_pixels: width_pixels,
          height_pixels: height_pixels,
          content_type: binary_data_content_type,
          sha256_hash: new_sha256_hash,
          data: resized_image_data,
          inserted_at: Timex.now("America/New_York"),
          updated_at: Timex.now("America/New_York")
        })
        |> Ecto.Changeset.apply_changes()

      {_count, 0, ms_to_next_bucket, _created_at, _updated_at} ->
        Process.sleep(
          ms_to_next_bucket +
            :rand.uniform(trunc(Application.get_env(:ex_rated, :bucket_time) / 10))
        )

        do_get_attachment(attachment, width, height)
    end
  end

  @doc """
  Gets a single attachment.

  Raises `Ecto.NoResultsError` if the Attachment does not exist.

  ## Examples

      iex> get_attachment!(123)
      %Attachment{}

      iex> get_attachment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_attachment!(id, attachment_schema \\ Attachment)

  def get_attachment!(id, attachment_schema) when is_integer(id),
    do: Repo.get!(attachment_schema, id)

  def get_attachment!(id, attachment_schema) when is_binary(id) do
    # dupe image uploads have the same SHA. Oops.
    handle_same_hash_for_multiple_possible_attachments(id, attachment_schema)
  end

  @doc """
  Creates a attachment.

  ## Examples

      iex> create_attachment(%{field: value})
      {:ok, %Attachment{}}

      iex> create_attachment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_attachment(attrs \\ %{}) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a attachment.

  ## Examples

      iex> update_attachment(attachment, %{field: new_value})
      {:ok, %Attachment{}}

      iex> update_attachment(attachment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_attachment(%Attachment{} = attachment, attrs) do
    attachment
    |> Attachment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Attachment.

  ## Examples

      iex> delete_attachment(attachment)
      {:ok, %Attachment{}}

      iex> delete_attachment(attachment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_attachment(%Attachment{} = attachment) do
    Repo.delete(attachment)
  end

  def delete_attachment(%AttachmentMetadata{} = attachment) do
    Repo.delete(attachment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking attachment changes.

  ## Examples

      iex> change_attachment(attachment)
      %Ecto.Changeset{source: %Attachment{}}

  """
  def change_attachment(%Attachment{} = attachment) do
    Attachment.changeset(attachment, %{})
  end
end
