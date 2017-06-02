defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Listing.Attachment do
  use Ecto.Migration

  def change do
    create table(:listing_attachments) do
      add :listing_id, references(:listings, on_delete: :nothing)
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

    create index(:listing_attachments, [:listing_id])
  end
end
