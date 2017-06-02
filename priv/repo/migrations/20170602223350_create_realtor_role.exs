defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Realtor.Role do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string

      timestamps()
    end

  end
end
