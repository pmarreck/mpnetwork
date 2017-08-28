defmodule Mpnetwork.Repo.Migrations.AddUniqueNameConstraintToOffices do
  use Ecto.Migration

  def change do
    create unique_index(:offices, [:name, :address])
  end
end
