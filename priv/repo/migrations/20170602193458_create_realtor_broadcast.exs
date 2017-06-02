defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Realtor.Broadcast do
  use Ecto.Migration

  def change do
    create table(:broadcasts) do
      add :user_id, :integer
      add :title, :string
      add :body, :text

      timestamps()
    end

  end
end
