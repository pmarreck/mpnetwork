defmodule Mpnetwork.Listing do
  @moduledoc """
  The boundary for the Listing system.
  """

  import Ecto.Query, warn: false
  alias Mpnetwork.Repo
  alias Briefly, as: Temp
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

  def list_attachments(listing_id, AttachmentMetadata) do
    Repo.all(
      from(
        attachment in AttachmentMetadata,
        where: attachment.listing_id == ^listing_id,
        order_by: [
          desc: attachment.is_image,
          desc: attachment.primary,
          asc: attachment.inserted_at
        ]
      )
    )
  end

  def list_attachments(listing_id, Attachment) do
    Repo.all(
      from(
        attachment in Attachment,
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

  def find_primary_image(listing_id, Attachment) do
    Repo.one(
      from(
        attachment in Attachment,
        where: attachment.listing_id == ^listing_id,
        where: attachment.is_image == true,
        order_by: [desc: attachment.primary],
        limit: 1
      )
    )
  end

  def find_primary_image(listing_id, AttachmentMetadata) do
    Repo.one(
      from(
        attachment in AttachmentMetadata,
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

  defp do_rotate_attachment(degrees, attachment) when degrees in [-90, 90] do
    import Mogrify
    use Mogrify.Options

    # write temp file to disk
    {:ok, tempfile} = Temp.create()
    File.write!(tempfile, attachment.data) # should close file handle
    # do rotation on disk
    rotated_image = (open(tempfile) |> add_option(option_rotate("#{degrees}")) |> quality("85") |> save)
    # read new file off disk into memory
    rotated_image_data = File.read!(rotated_image.path)
    # parse new file's dimensions
    {binary_data_content_type, width_pixels, height_pixels} =
      Upload.extract_meta_from_binary_data(rotated_image_data, attachment.content_type)
    new_sha256_hash = :crypto.hash(:sha256, rotated_image_data)
    # clean up rotated file
    File.rm!(rotated_image.path)

    # return the modified attachment changeset (not saved yet)
    attachment
    |> Attachment.changeset(%{
      width_pixels: width_pixels,
      height_pixels: height_pixels,
      content_type: binary_data_content_type,
      sha256_hash: new_sha256_hash,
      data: rotated_image_data,
      inserted_at: attachment.inserted_at,
      updated_at: Timex.now("EDT")
    })
  end

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
    # first we will get the original attachment from the DB BY SHA256, filtering on images-only
    Repo.one!(
      from(
        attachment in Attachment,
        where: attachment.sha256_hash == ^id,
        where: attachment.is_image == true,
        limit: 1
      )
    )
    |> do_get_attachment(width, height)
  end

  defp do_get_attachment(attachment, width, height) do
    # We need to rate-limit mogrify to avoid server memory spikes
    case ExRated.inspect_bucket(
           :mogrify_rate_limiter,
           Application.get_env(:ex_rated, :bucket_time),
           Application.get_env(:ex_rated, :bucket_limit)
         ) do
      {_count, count_remaining, _ms_to_next_bucket, _created_at, _updated_at}
      when count_remaining > 0 ->
        import Mogrify
        # then we will write its binary data to a local tempfile
        {:ok, path} = Temp.create()
        # should close file automatically
        File.write!(path, attachment.data)
        # then we will resize it
        image = open(path) |> resize("#{width}x#{height}>") |> save
        # then we will reread the new file's binary data
        new_image_data = File.read!(image.path)
        # then we will parse the new file's actual dimensions
        {binary_data_content_type, width_pixels, height_pixels} =
          Upload.extract_meta_from_binary_data(new_image_data, attachment.content_type)
        # clean up the non-tempfile
        File.rm!(image.path)
        # then we will return this (which currently gets stored in the app cache)
        # applies WITHOUT saving, FYI! DO NOT SAVE THIS :O
        attachment
        |> Attachment.changeset(%{
          width_pixels: width_pixels,
          height_pixels: height_pixels,
          content_type: binary_data_content_type,
          sha256_hash: :crypto.hash(:sha256, new_image_data),
          data: new_image_data,
          inserted_at: Timex.now("EDT"),
          updated_at: Timex.now("EDT")
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

  def get_attachment!(id, attachment_schema) when is_binary(id),
    do: Repo.get_by!(attachment_schema, sha256_hash: id)

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
