# Soooo in migration 20200717194021_add_on_market_date_to_listings.exs, I created
# a dependency on actual time (CURRENT_DATE) which ended up a bad design because
# it breaks reimport of data (since OMD is no longer valid at that point per the constraint),
# so I can't upgrade the DB for example.
# I didn't even consider this possibility, but hindsight is 20/20!

defmodule Mpnetwork.Repo.Migrations.FixOnMarketDateConstraint do
  use Ecto.Migration
  alias Mpnetwork.Ecto.MigrationSupport, as: MS

  # EDIT: You MUST add data cleanup before instituting the constraint check or the deploy will fail late
  # due to Postgres not accepting it (it actually checks all the existing data! Good Postgres! :] )
  # and the gigalixir status will be UNHEALTHY!

  defp clean_data_first_sql() do
    # forces on-market-date to not be outside 2 weeks of the last updated_at date
    """
      UPDATE listings SET omd_on = (updated_at::date + interval '14 days') WHERE updated_at IS NOT NULL AND omd_on IS NOT NULL AND draft = false AND omd_on > (updated_at::date + interval '14 days');
    """
  end

  def change do
    [undo_view] = MS.undo_softdelete_view_sql(:listings)
    [redo_view] = MS.redo_softdelete_view_sql(:listings)
    execute(undo_view, redo_view)
    execute("ALTER TABLE listings DROP CONSTRAINT IF EXISTS omd_between_now_and_15_days", "") # do not reinstitute the 💩 constraint in a down. Sorry.
    execute(clean_data_first_sql(),"")
    # Has the updated-at been updated yet at this point? Coalesce to current date just in case
    create constraint(:listings, :omd_between_now_and_15_days,
      check: "omd_on IS NULL OR draft = true OR (omd_on < (COALESCE(updated_at::date, CURRENT_DATE) + interval '15 days'))")
    execute(redo_view, undo_view)
  end
end
