# Because it's almost impossible to make sure I recreate this trigger correctly
# and dropping it is necessary to modify the user_id field of listings,
# I'm pulling in the relevant function from a previous migration
# edit: WARNING TO FUTURE PETER: THIS DOES NOT WORK, MIX CONTEXT IS NOT AVAILABLE
# Please refer to migration_support.ex for search index/trigger/sproc definitions
# Code.require_file("20190710200023_add_draft_to_fulltext_searchable_fields.exs", "priv/repo/migrations")

defmodule Mpnetwork.Repo.Migrations.ChangeDeleteAllToNilifyAllOnListingForUserFk do
  use Mpnetwork.Ecto.MigrationSupport

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
