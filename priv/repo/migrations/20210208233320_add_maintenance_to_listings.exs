defmodule Mpnetwork.Repo.Migrations.AddMaintenanceToListings do
  use Ecto.Migration
  alias Mpnetwork.Ecto.MigrationSupport, as: MS

  defp undo_view, do: List.first(MS.undo_softdelete_view_sql(:listings))
  defp redo_view, do: List.first(MS.redo_softdelete_view_sql(:listings))

  def change do
    execute(undo_view(), redo_view())
    alter table(:listings) do
      add :maintenance_usd, :integer
    end
    execute(redo_view(), undo_view())
  end

end
