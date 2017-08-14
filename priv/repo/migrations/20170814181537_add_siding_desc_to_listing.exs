defmodule Mpnetwork.Repo.Migrations.AddSidingDescToListing do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :siding_desc, :string
    end
  end
end
