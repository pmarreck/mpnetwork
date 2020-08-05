defmodule Mpnetwork.Repo.Migrations.AddOnMarketDateToListings do
  use Ecto.Migration
  alias Mpnetwork.Ecto.MigrationSupport, as: MS

  # EDIT: You MUST add data cleanup before instituting the constraint check or the deploy will fail late
  # due to Postgres not accepting it (it actually checks all the existing data! Good Postgres! :] )
  # and the gigalixir status will be UNHEALTHY!

  defp clean_data_first_sql() do
    "UPDATE listings SET listing_status_type = NULL WHERE listing_status_type = 'CS' AND omd_on IS NULL"
  end

  def change do
    [undo_view] = MS.undo_softdelete_view_sql(:listings)
    [redo_view] = MS.redo_softdelete_view_sql(:listings)
    execute(undo_view, redo_view)
    alter table(:listings) do
      add :omd_on, :date
    end
    execute(clean_data_first_sql(),"")
    create constraint(:listings, :omd_between_now_and_15_days,
      check: "omd_on IS NULL OR (omd_on > (CURRENT_DATE at time zone 'EST')::date AND omd_on < ((CURRENT_DATE at time zone 'EST')::date + interval '15 days'))")
    create constraint(:listings, :omd_exists_if_lst_is_cs,
      check: "listing_status_type != 'CS' OR omd_on IS NOT NULL")
    execute(redo_view, undo_view)
  end
end
