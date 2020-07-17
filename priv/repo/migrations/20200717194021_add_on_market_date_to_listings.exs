defmodule Mpnetwork.Repo.Migrations.AddOnMarketDateToListings do
  use Ecto.Migration
  alias Mpnetwork.Ecto.MigrationSupport, as: MS

  def change do
    [undo_view] = MS.undo_softdelete_view_sql(:listings)
    [redo_view] = MS.redo_softdelete_view_sql(:listings)
    execute(undo_view, redo_view)
    alter table(:listings) do
      add :omd_on, :date
    end
    create constraint(:listings, :omd_between_now_and_15_days,
      check: "omd_on IS NULL OR (omd_on > (CURRENT_DATE at time zone 'EST')::date AND omd_on < ((CURRENT_DATE at time zone 'EST')::date + interval '15 days'))")
    create constraint(:listings, :omd_exists_if_lst_is_cs,
      check: "listing_status_type != 'CS' OR omd_on IS NOT NULL")
    execute(redo_view, undo_view)
  end
end
