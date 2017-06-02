defmodule Mpnetwork.Listing.Attachment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Listing.Attachment


  schema "listing_attachments" do
    field :listing_id, :id
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

  @doc false
  def changeset(%Attachment{} = attachment, attrs) do
    attachment
    |> cast(attrs, [:sha256_hash, :primary, :content_type, :original_filename, :width_pixels, :height_pixels, :data])
    |> validate_required([:sha256_hash, :primary, :content_type, :original_filename, :width_pixels, :height_pixels, :data])
  end
end
