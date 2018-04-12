defmodule Mpnetwork.Repo.Migrations.AdditionalRentalAttributes do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :pets_ok, :boolean
      add :smoking_ok, :boolean
    end
  end
end
