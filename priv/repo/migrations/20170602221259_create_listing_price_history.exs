defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Listing.PriceHistory do
  use Ecto.Migration

  def change do
    create table(:listing_price_histories) do
      add :price_usd, :integer
      add :listing_id, references(:listings, on_delete: :nothing)

      timestamps()
    end

    create index(:listing_price_histories, [:listing_id])
  end
end
