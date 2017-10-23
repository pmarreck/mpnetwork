defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Listing.Attachment do
  use Ecto.Migration

  def change do
    create table(:attachments) do
      add :listing_id, :bigint
      add :primary, :boolean, default: false, null: false
      add :content_type, :string
      add :is_image, :boolean, default: false, null: false
      add :original_filename, :string
      add :width_pixels, :integer
      add :height_pixels, :integer
      add :sha256_hash, :binary
      add :data, :binary

      timestamps()
    end
    alter table(:attachments) do
      modify :listing_id, references(:listings, on_delete: :delete_all)
    end

    create index(:attachments, [:listing_id])
  end
end
