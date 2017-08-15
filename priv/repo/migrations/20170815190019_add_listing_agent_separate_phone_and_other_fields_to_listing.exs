defmodule Mpnetwork.Repo.Migrations.AddListingAgentSeparatePhoneAndOtherFieldsToListing do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :colisting_agent_id, references(:users, on_delete: :nothing)
      add :listing_agent_phone, :string
      add :colisting_agent_phone, :string
      add :rental_price_usd, :integer
      add :negotiate_direct, :boolean
    end
  end
end
