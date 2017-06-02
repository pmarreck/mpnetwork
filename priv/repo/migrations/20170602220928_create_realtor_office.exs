defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Realtor.Office do
  use Ecto.Migration

  def change do
    create table(:offices) do
      add :name, :string

      timestamps()
    end

  end
end
