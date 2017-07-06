defmodule Mpnetwork.Listing do
  @moduledoc """
  The boundary for the Listing system.
  """

  import Ecto.Query, warn: false
  import Mogrify
  alias Mpnetwork.Repo
  alias Briefly, as: Temp

  alias Mpnetwork.Listing.Attachment

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
  def list_attachments(listing_id) do
    Repo.all(
      from attachment in Attachment,
      where: attachment.listing_id == ^listing_id,
      order_by: [desc: attachment.is_image, desc: attachment.primary]
    )
  end

  @doc """
  Returns the primary image for a given listing_id.

  ## Examples

      iex> find_primary_image(1)
      [%Attachment{}, ...]

  """
  def find_primary_image(listing_id) do
    Repo.one(
      from attachment in Attachment,
      where: attachment.listing_id == ^listing_id,
      where: attachment.is_image == true,
      order_by: [desc: attachment.primary],
      limit: 1
    )
  end

  @doc """
  Returns a map of listing_ids to the primary image for a given listing.
  TODO: rewrite this to make the DB do the work instead of requerying.

  ## Examples

      iex> primary_images_for_listings(1)
      %{1 => %Attachment{}, ...}

  """
  def primary_images_for_listings(listings) do
    Enum.reduce(listings, %{}, fn(listing, map) ->
      %{listing.id => find_primary_image(listing.id)}
      |> Enum.into(map)
      end
    )
  end

  defp extract_meta_from_binary_data(binary_data, claimed_content_type) do
    case ExImageInfo.info(binary_data) do
      nil          -> {claimed_content_type, nil, nil}
      {a, b, c, _} -> {a, b, c}
    end
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
  def get_attachment!({id, width, height}) do
    # first we will get the original attachment from the DB, filtering on images-only
    # Repo.get!(Attachment, id)
    attachment = Repo.one!(
      from attachment in Attachment,
      where: attachment.id == ^id,
      where: attachment.is_image == true,
      limit: 1
    )
    # then we will write its binary data to a local tempfile
    {:ok, path} = Temp.create
    File.write!(path, attachment.data) # should close file automatically
    # then we will resize it
    image = open(path) |> resize("#{width}x#{height}") |> save
    # then we will reread the new file's binary data
    new_image_data = File.read!(image.path)
    # then we will parse the new file's actual dimensions
    {binary_data_content_type, width_pixels, height_pixels} =
      extract_meta_from_binary_data(new_image_data, attachment.content_type)
    # then we will return this (which currently gets stored in the app cache)
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
    |> Ecto.Changeset.apply_changes # applies WITHOUT saving, FYI! DO NOT SAVE THIS :O
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
  def get_attachment!(id), do: Repo.get!(Attachment, id)

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
