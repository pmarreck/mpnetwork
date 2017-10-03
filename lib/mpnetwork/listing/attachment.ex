defmodule Mpnetwork.Listing.Attachment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Listing.Attachment
  alias Mpnetwork.Realtor.Listing


  schema "listing_attachments" do
    # field :listing_id, :id
    belongs_to :listing, Listing
    field :content_type, :string
    field :is_image, :boolean, default: false
    field :width_pixels, :integer
    field :height_pixels, :integer
    field :original_filename, :string
    field :primary, :boolean, default: false
    field :sha256_hash, :binary
    field :data, :binary

    timestamps()
  end

  def validate_primary_only_set_on_images(changeset) do
    primary  = get_field(changeset, :primary)
    is_image = get_field(changeset, :is_image)
    if primary && !is_image do
      add_error(changeset, :primary, "cannot be set on non-images")
    else
      changeset
    end
  end

  @doc false
  def changeset(%Attachment{} = attachment, attrs) do
    attachment
    |> cast(attrs, [:listing_id, :sha256_hash, :primary, :content_type, :is_image, :original_filename, :width_pixels, :height_pixels, :data])
    |> validate_required([:listing_id, :sha256_hash, :primary, :is_image, :content_type, :original_filename, :data])
    |> validate_primary_only_set_on_images
  end
end
