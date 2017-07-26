defmodule Mpnetwork.Repo.Migrations.AddFieldsToOffices do
  use Ecto.Migration

  def change do
    alter table(:offices) do
      add :address, :string
      add :city, :string
      add :state, :string
      add :zip, :string
      add :phone, :string
    end
  end
  
end
