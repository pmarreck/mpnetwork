defmodule Mpnetwork.Repo.Migrations.AddCitextExtensionToPostgres do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;"
  end

  def down do
    execute "DROP EXTENSION citext;"
  end
end
