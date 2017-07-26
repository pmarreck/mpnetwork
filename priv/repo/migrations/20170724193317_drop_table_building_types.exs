defmodule Mpnetwork.Repo.Migrations.DropTableBuildingTypes do
  use Ecto.Migration

  def up do
    alter table(:listings) do
      remove :building_type_id
    end
    drop table(:building_types)
  end

  def down do
    warn "WARNING: any destroyed building_types data will not be restored"
    create table(:building_types) do
      add :name, :string

      timestamps()
    end
    alter table(:listings) do
      add :building_type_id, references(:building_types, on_delete: :nothing)
    end
  end

  defp warn(w) do
    IO.puts IO.ANSI.format [:red, :blink_slow, w]
  end

end
