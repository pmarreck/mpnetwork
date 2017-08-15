defmodule Mpnetwork.Repo.Migrations.RenameOfficeIdToBrokerIdOnListing do
  use Ecto.Migration

  def change do
    rename table(:listings), :office_id, to: :broker_id
  end
end
