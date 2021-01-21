defmodule Mpnetwork.Repo.Migrations.AddSecDepAndCommissionPaidByToListing do
  use Ecto.Migration
  alias Mpnetwork.Ecto.MigrationSupport, as: MS

  # remember that if you change or add fields on Listings, you have to
  # drop and recreate the undeleted view as well
  def change do
    [undo_view] = MS.undo_softdelete_view_sql(:listings)
    [redo_view] = MS.redo_softdelete_view_sql(:listings)
    execute(undo_view, redo_view)
    alter table(:listings) do
      add :sec_dep, :string
      add :commission_paid_by, :string
    end
    execute(redo_view, undo_view)
  end
end
