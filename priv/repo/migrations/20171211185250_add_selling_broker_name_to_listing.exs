defmodule Mpnetwork.Repo.Migrations.AddSellingBrokerNameToListing do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :selling_agent_phone, :string
      add :selling_broker_name, :string
    end
  end
end
