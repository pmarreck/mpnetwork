defmodule Mpnetwork.Repo.Migrations.AddNewListingStatusTypeToEnum do
  use Ecto.Migration
  @disable_ddl_transaction true # altering types cannot be done in a transaction

  def up do
    # for idempotency...
    execute """
      DELETE FROM pg_enum
      WHERE enumlabel = 'EXP'
      AND enumtypid = (
        SELECT oid FROM pg_type WHERE typname = 'listing_status_type'
      )
    """
    execute """
      ALTER TYPE listing_status_type ADD VALUE 'EXP';
    """
    # Technically we should probably also be updating the search index/trigger/stored proc,
    # but it already handles adding an indexable "expired" keyword if the expiration date is in the past...
    # Of course, I just realized it only does that if the listing is updated...
    # Which is the daily-expiration-checker job I'm about to write.
  end

  def down do
    # OK so to do this properly we'd need to
    # 1) UPDATE any values using the about-to-be-removed value to something else (NULL?)
    # 2) convert the column to varchar
    # 3) drop the old type
    # 4) recreate the new type without the new value
    # 5) convert the varchar column back to that new type
    # We are not going to do this proper because that is too much work
    # and this is a down migration that will almost never (if ever) be run.
    # If this was an up migration, I'd do it proper. So...
    # We're going to update any existing rows that use the about-to-be-removed value to NULL
    # and then directly modify the pg_enum table to remove the value.

    execute """
      UPDATE listings SET listing_status_type = NULL WHERE listing_status_type = 'EXP';
    """
    execute """
      DELETE FROM pg_enum
      WHERE enumlabel = 'EXP'
      AND enumtypid = (
        SELECT oid FROM pg_type WHERE typname = 'listing_status_type'
      )
    """
  end

end
