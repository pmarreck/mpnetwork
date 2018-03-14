defmodule Mpnetwork.Listing do
  @moduledoc """
  The boundary for the Listing system.
  """

  import Ecto.Query, warn: false
  alias Mpnetwork.Repo
  alias Briefly, as: Temp
  require Mpnetwork.Upload
  alias Mpnetwork.{Upload, Crypto}

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

  @doc """
  Computes the link code for an emailed broker listing.

  ## Examples

      iex> public_broker_full_code(listing)
      "f3o427dr2kpe2bdxzoswbaivcpqt4g7xuqd3xey2dnv7lm4yylhq"

  """
  def public_broker_full_code(
        listing,
        expiration_days_since_unix_epoch \\ two_weeks_from_now_in_unix_epoch_days()
      ) do
    do_listing_code(listing, :broker, expiration_days_since_unix_epoch)
  end

  @doc """
  Computes the link code for an emailed client listing.

  ## Examples

      iex> public_client_full_code(listing)
      "f3o427dr2kpe2bdxzoswbaivcpqt4g7xuqd3xey2dnv7lm4yylhq"

  """
  def public_client_full_code(
        listing,
        expiration_days_since_unix_epoch \\ two_weeks_from_now_in_unix_epoch_days()
      ) do
    do_listing_code(listing, :client, expiration_days_since_unix_epoch)
  end

  @doc """
  Computes the link code for an emailed customer listing.

  ## Examples

      iex> public_customer_full_code(listing)
      "f3o427dr2kpe2bdxzoswbaivcpqt4g7xuqd3xey2dnv7lm4yylhq"

  """
  def public_customer_full_code(
        listing,
        expiration_days_since_unix_epoch \\ two_weeks_from_now_in_unix_epoch_days()
      ) do
    do_listing_code(listing, :customer, expiration_days_since_unix_epoch)
  end

  defp do_listing_code(listing, recipient_type, expiration_days_since_unix_epoch) do
    {listing.id, expiration_days_since_unix_epoch, recipient_type}
    |> Crypto.encrypt()
  end

  def from_listing_code(ciphertext, recip) do
    {listing_id, exp_day, ^recip} = Crypto.decrypt(ciphertext)
    {listing_id, timex_datetime_from_unix_epoch_days(exp_day)}
  end

  def now_in_unix_epoch_days do
    in_unix_epoch_days()
  end

  def in_unix_epoch_days(time \\ Timex.today()) do
    (Timex.to_unix(time) / (60 * 60 * 24)) |> trunc
  end

  defp two_weeks_from_now_in_unix_epoch_days do
    now_in_unix_epoch_days() + 14
  end

  defp timex_datetime_from_unix_epoch_days(days) do
    Timex.from_unix(days * 24 * 60 * 60)
  end
end
