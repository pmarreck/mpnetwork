defmodule Mpnetwork.Repo.Migrations.AddClosingDataFieldsToListing do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :uc_on, :date
      add :prop_closing_on, :date
      add :closed_on, :date
      add :closing_price_usd, :integer
      add :purchaser, :string
      add :moved_from, :string
    end
  end

end
