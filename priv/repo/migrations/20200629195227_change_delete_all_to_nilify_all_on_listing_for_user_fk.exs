# Because it's almost impossible to make sure I recreate this trigger correctly
# and dropping it is necessary to modify the user_id field of listings,
# I'm pulling in the relevant function from a previous migration
Code.require_file("20190710200023_add_draft_to_fulltext_searchable_fields.exs", "priv/repo/migrations")

defmodule Mpnetwork.Repo.Migrations.ChangeDeleteAllToNilifyAllOnListingForUserFk do
  use Ecto.Migration

  import Mpnetwork.Repo.Migrations.AddDraftToFulltextSearchableFields, only: [listing_search_update_trigger_creation_sql: 0]


  defp undo_softdelete(table) do
    execute(
      """
      DO $$
      BEGIN
        PERFORM reverse_table_soft_delete('#{table}');
      END $$
      """
    )
  end

  defp undo_search_index_trigger() do
    execute(
      "DROP TRIGGER IF EXISTS listing_search_update ON listings;"
    )
  end

  defp redo_softdelete(table) do
    execute(
      """
      DO $$
      BEGIN
        PERFORM prepare_table_for_soft_delete('#{table}');
      END $$
      """
    )
  end

  defp redo_search_index_trigger() do
    execute(listing_search_update_trigger_creation_sql())
  end

  def up do
    drop constraint(:listings, "listings_user_id_fkey")

    # unfortunately we'll have to temporarily drop soft-delete support on listings and then re-enable it
    undo_softdelete(:listings)

    # oh god. now I have to drop and recreate the search index updating triggers that depend on user_id
    undo_search_index_trigger()

    alter table(:listings, prefix: "public") do
      modify :user_id, references(:users, on_delete: :nilify_all)
    end

    redo_search_index_trigger()

    redo_softdelete(:listings)
  end

  def down do
    drop constraint(:listings, "listings_user_id_fkey")

    undo_softdelete(:listings)

    undo_search_index_trigger()

    alter table(:listings, prefix: "public") do
      modify :user_id, references(:users, on_delete: :delete_all)
    end

    redo_search_index_trigger()

    redo_softdelete(:listings)
  end
end
