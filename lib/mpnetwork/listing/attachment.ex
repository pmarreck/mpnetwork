defmodule Mpnetwork.Listing.Attachment do
  use Mpnetwork.Ecto.Schema

  import Ecto.Query
  alias Mpnetwork.Listing.Attachment
  alias Mpnetwork.Realtor.Listing
  alias Mpnetwork.Repo

  schema "attachments" do
    # field :listing_id, :id
    belongs_to(:listing, Listing)
    field(:content_type, :string)
    field(:is_image, :boolean, default: false)
    field(:width_pixels, :integer)
    field(:height_pixels, :integer)
    field(:original_filename, :string)
    field(:primary, :boolean, default: false)
    field(:sha256_hash, :binary)
    field(:data, :binary)

    timestamps()
  end

  def validate_primary_only_set_on_images(changeset) do
    primary = get_field(changeset, :primary)
    is_image = get_field(changeset, :is_image)

    if primary && !is_image do
      add_error(changeset, :primary, "cannot be set on non-images")
    else
      changeset
    end
  end

  def validate_not_too_many(changeset) do
    listing_id = get_field(changeset, :listing_id)

    if listing_id do
      limit_per_listing = Application.get_env(:mpnetwork, :max_attachments_per_listing)

      how_many_already =
        Attachment
        |> where([a], a.listing_id == ^listing_id)
        |> select([a], count(a.listing_id))
        |> Repo.one()

      if how_many_already >= limit_per_listing do
        add_error(changeset, :listing_id, "already has the limit of #{} attachments per listing")
      else
        changeset
      end
    else
      changeset
    end
  end

  @doc false
  def changeset(%Attachment{} = attachment, attrs) do
    attachment
    |> cast(attrs, [
      :listing_id,
      :sha256_hash,
      :primary,
      :content_type,
      :is_image,
      :original_filename,
      :width_pixels,
      :height_pixels,
      :data
    ])
    |> validate_required([
      :listing_id,
      :sha256_hash,
      :primary,
      :is_image,
      :content_type,
      :original_filename,
      :data
    ])
    |> validate_primary_only_set_on_images
    |> validate_length(:content_type, max: 255, count: :codepoints)
    |> validate_length(:original_filename, max: 255, count: :codepoints)
    |> validate_not_too_many
  end
end
