defmodule Mpnetwork.Repo.Migrations.AddHandicapAccessBoolAndDescToListing do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :handicap_access, :boolean
      add :handicap_access_desc, :string
    end
  end
end
