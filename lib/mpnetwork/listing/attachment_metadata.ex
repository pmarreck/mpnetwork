# This is basically a read-only module that is the same as the Attachment module
# but excludes the actual binary data for performance reasons

defmodule Mpnetwork.Listing.AttachmentMetadata do
  use Ecto.Schema
  # import Ecto.Changeset
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
    # field :data, :binary # excluded; if needed, use Attachment

    timestamps()
  end

end
