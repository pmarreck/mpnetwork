defmodule Mpnetwork.Repo.Migrations.CreateCache do
  use Ecto.Migration

  def change do
    create table(:cache) do
      add :key, :binary
      add :sha256_hash, :binary # hash of value
      add :value, :binary
      # add :metadata, :map

      timestamps()
    end

    create unique_index(:cache, [:key])
    # create unique_index(:cache, [:sha256_hash]) # pain of handling dupes and expiring parents properly with dependent children is not worth it at this time

  end
end
