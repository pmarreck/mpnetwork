defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Realtor.Listing.BuildingType do
  use Ecto.Migration

  def change do
    create table(:building_types) do
      add :name, :string

      timestamps()
    end

  end
end
