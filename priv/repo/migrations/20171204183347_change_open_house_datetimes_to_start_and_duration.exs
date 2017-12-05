defmodule Mpnetwork.Repo.Migrations.ChangeOpenHouseDatetimesToStartAndDuration do
  use Ecto.Migration

  # this is a behemoth of a migration!

  def up do
    # drop constraints, validations and indexes around end_at following start_at
    drop index("listings", [:next_broker_oh_start_at])
    drop index("listings", [:next_broker_oh_end_at])
    drop index("listings", [:next_cust_oh_start_at])
    drop index("listings", [:next_cust_oh_end_at])
    execute "ALTER TABLE listings DROP CONSTRAINT IF EXISTS broker_oh_start_earlier_than_end;"
    execute "ALTER TABLE listings DROP CONSTRAINT IF EXISTS cust_oh_start_earlier_than_end;"
    execute "ALTER TABLE listings DROP CONSTRAINT IF EXISTS broker_oh_datetimes_same_day;"
    execute "ALTER TABLE listings DROP CONSTRAINT IF EXISTS cust_oh_datetimes_same_day;"
    # rename next_broker_oh_start_at -> first_broker_oh_start_at
    rename table(:listings), :next_broker_oh_start_at, to: :first_broker_oh_start_at
    # rename next_broker_oh_end_at -> second_broker_oh_start_at
    rename table(:listings), :next_broker_oh_end_at, to: :second_broker_oh_start_at
    # rename next_cust_oh_start_at -> first_cust_oh_start_at
    rename table(:listings), :next_cust_oh_start_at, to: :first_cust_oh_start_at
    # rename next_cust_oh_end_at -> second_cust_oh_start_at
    rename table(:listings), :next_cust_oh_end_at, to: :second_cust_oh_start_at
    # add first_broker_oh_mins, second_broker_oh_mins, first_cust_oh_mins, second_cust_oh_mins as positive integers (validate in schema!)
    alter table(:listings) do
      add :first_broker_oh_mins, :smallint
      add :second_broker_oh_mins, :smallint
      add :first_cust_oh_mins, :smallint
      add :second_cust_oh_mins, :smallint
    end
    execute "ALTER TABLE listings ADD CONSTRAINT first_broker_oh_mins_positive CHECK (first_broker_oh_mins > 0);"
    execute "ALTER TABLE listings ADD CONSTRAINT second_broker_oh_mins_positive CHECK (second_broker_oh_mins > 0);"
    execute "ALTER TABLE listings ADD CONSTRAINT first_cust_oh_mins_positive CHECK (first_cust_oh_mins > 0);"
    execute "ALTER TABLE listings ADD CONSTRAINT second_cust_oh_mins_positive CHECK (second_cust_oh_mins > 0);"
    # set first_broker_oh_mins = second_broker_oh_start_at - first_broker_oh_start_at where first_broker_oh_start_at is not nil (in minutes, be careful of computation!)
    execute "UPDATE listings SET first_broker_oh_mins = EXTRACT(epoch FROM (second_broker_oh_start_at - first_broker_oh_start_at)/60) WHERE first_broker_oh_start_at IS NOT NULL"
    # set first_cust_oh_mins = second_cust_oh_start_at - first_cust_oh_start_at where first_cust_oh_start_at is not nil (in minutes, be careful of computation!)
    execute "UPDATE listings SET first_cust_oh_mins = EXTRACT(epoch FROM (second_cust_oh_start_at - first_cust_oh_start_at)/60) WHERE first_cust_oh_start_at IS NOT NULL"
    # set second_broker_oh_start_at to nil
    execute "UPDATE listings SET second_broker_oh_start_at = NULL"
    # set second_cust_oh_start_at to nil
    execute "UPDATE listings SET second_cust_oh_start_at = NULL"
    # recreate indexes on time fields
    create index("listings", [:first_broker_oh_start_at])
    create index("listings", [:second_broker_oh_start_at])
    create index("listings", [:first_cust_oh_start_at])
    create index("listings", [:second_cust_oh_start_at])
  end

  def down do
    # now do the above, but the exact opposite, in the opposite order

    drop index("listings", [:first_broker_oh_start_at])
    drop index("listings", [:second_broker_oh_start_at])
    drop index("listings", [:first_cust_oh_start_at])
    drop index("listings", [:second_cust_oh_start_at])

    execute "UPDATE listings SET second_cust_oh_start_at = first_cust_oh_start_at + (first_cust_oh_mins * interval '1 minute') WHERE first_cust_oh_start_at IS NOT NULL"

    execute "UPDATE listings SET second_broker_oh_start_at = first_broker_oh_start_at + (first_broker_oh_mins * interval '1 minute') WHERE first_broker_oh_start_at IS NOT NULL"

    execute "ALTER TABLE listings DROP CONSTRAINT IF EXISTS first_broker_oh_mins_positive;"
    execute "ALTER TABLE listings DROP CONSTRAINT IF EXISTS second_broker_oh_mins_positive;"
    execute "ALTER TABLE listings DROP CONSTRAINT IF EXISTS first_cust_oh_mins_positive;"
    execute "ALTER TABLE listings DROP CONSTRAINT IF EXISTS second_cust_oh_mins_positive;"

    alter table(:listings) do
      remove :first_broker_oh_mins
      remove :second_broker_oh_mins
      remove :first_cust_oh_mins
      remove :second_cust_oh_mins
    end

    rename table(:listings), :second_cust_oh_start_at, to: :next_cust_oh_end_at
    rename table(:listings), :first_cust_oh_start_at, to: :next_cust_oh_start_at
    rename table(:listings), :second_broker_oh_start_at, to: :next_broker_oh_end_at
    rename table(:listings), :first_broker_oh_start_at, to: :next_broker_oh_start_at

    execute "ALTER TABLE listings ADD CONSTRAINT broker_oh_start_earlier_than_end CHECK (next_broker_oh_start_at < next_broker_oh_end_at);"
    execute "ALTER TABLE listings ADD CONSTRAINT cust_oh_start_earlier_than_end CHECK (next_cust_oh_start_at < next_cust_oh_end_at);"
    execute "ALTER TABLE listings ADD CONSTRAINT broker_oh_datetimes_same_day CHECK (EXTRACT(YEAR FROM next_broker_oh_start_at) = EXTRACT(YEAR FROM next_broker_oh_end_at) AND EXTRACT(DOY FROM next_broker_oh_start_at) = EXTRACT(DOY FROM next_broker_oh_end_at));"
    execute "ALTER TABLE listings ADD CONSTRAINT cust_oh_datetimes_same_day CHECK (EXTRACT(YEAR FROM next_cust_oh_start_at) = EXTRACT(YEAR FROM next_cust_oh_end_at) AND EXTRACT(DOY FROM next_cust_oh_start_at) = EXTRACT(DOY FROM next_cust_oh_end_at));"

    create index("listings", [:next_broker_oh_start_at])
    create index("listings", [:next_broker_oh_end_at])
    create index("listings", [:next_cust_oh_start_at])
    create index("listings", [:next_cust_oh_end_at])
  end
end
