defmodule Mpnetwork.Repo.Migrations.ChangeUserNameAndEmailColumnTypeToCitextWithProperIndices do
  use Ecto.Migration

  def change do
    drop unique_index(:users, :username)
    drop unique_index(:users, :email)
    alter table(:users) do
      modify :username, :citext
      modify :email, :citext
    end
    create unique_index(:users, :username)
    create unique_index(:users, :email)
  end
end
