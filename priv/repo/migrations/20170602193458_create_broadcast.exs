defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Realtor.Broadcast do
  use Ecto.Migration

  def change do
    create table(:broadcasts) do
      add :user_id, :bigint
      add :title, :string
      add :body, :text

      timestamps()
    end

    alter table(:broadcasts) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end

  end
end
