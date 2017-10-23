defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Realtor.Office do
  use Ecto.Migration

  def change do
    create table(:offices) do
      add :name, :string
      add :address, :string
      add :city, :string
      add :state, :string
      add :zip, :string
      add :phone, :string
      timestamps()
    end

    # alter table(:offices) do
    #   modify(:id, :bigint)
    # end

  end
end
