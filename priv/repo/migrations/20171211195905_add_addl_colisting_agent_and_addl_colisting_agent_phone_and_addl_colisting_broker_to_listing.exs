defmodule Mpnetwork.Repo.Migrations.AddAddlColistingAgentAndAddlColistingAgentPhoneAndAddlColistingBrokerToListing do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :addl_listing_agent_name, :string
      add :addl_listing_agent_phone, :string
      add :addl_listing_broker_name, :string
    end
  end
end
