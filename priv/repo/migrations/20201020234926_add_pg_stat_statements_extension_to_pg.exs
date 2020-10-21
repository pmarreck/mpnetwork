defmodule Mpnetwork.Repo.Migrations.AddPgStatStatementsExtensionToPg do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;"
  end

  def down do
    execute "DROP EXTENSION pg_stat_statements;"
  end
end
