defmodule Mpnetwork.Repo.Migrations.AddAdditionalIndexesToAttachmentsTable do
  use Ecto.Migration

  def change do
    create index(:attachments, :primary)
    create index(:attachments, :content_type)
    create index(:attachments, :is_image)
    create index(:attachments, :sha256_hash)
    create index(:attachments, :inserted_at)
    create index(:attachments, :updated_at)
  end
end
