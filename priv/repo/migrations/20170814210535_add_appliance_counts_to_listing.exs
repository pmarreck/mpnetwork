defmodule Mpnetwork.Repo.Migrations.AddApplianceCountsToListing do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :num_stoves, :integer
      add :num_refrigs, :integer
      add :num_washers, :integer
      add :num_dryers, :integer
      add :num_dishwashers, :integer
      add :num_half_garages, :integer
    end
  end
end
