defmodule Mpnetwork.Repo.Migrations.AddCanceledToObanJobStateEnum do
  use Ecto.Migration
  @disable_ddl_transaction true # altering types cannot be done in a transaction

  def up do
    execute """
      ALTER TYPE oban_job_state ADD VALUE IF NOT EXISTS 'cancelled'
    """
  end

  def down do
    raise "Removing an enum type value must be done in a separate migration to preserve data integrity!"
  end
end
