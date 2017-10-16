defmodule Mpnetwork.Repo.Migrations.AddAdditionalIndexesToAttachmentsTable do
  use Ecto.Migration

  def change do
    create index(:listing_attachments, :primary)
    create index(:listing_attachments, :content_type)
    create index(:listing_attachments, :is_image)
    create index(:listing_attachments, :sha256_hash)
    create index(:listing_attachments, :inserted_at)
    create index(:listing_attachments, :updated_at)
  end
end
