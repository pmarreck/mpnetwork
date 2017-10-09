defmodule Mpnetwork.Repo.Migrations.ChangeUserNameAndEmailColumnTypeToCitextWithProperIndices do
  use Ecto.Migration

  def up do
    drop unique_index(:users, :username)
    drop unique_index(:users, :email)
    alter table(:users) do
      modify :username, :citext
      modify :email, :citext
    end
    create unique_index(:users, :username)
    create unique_index(:users, :email)
  end

  def down do
    drop unique_index(:users, :username)
    drop unique_index(:users, :email)
    alter table(:users) do
      modify :username, :string
      modify :email, :string
    end
    create unique_index(:users, :username)
    create unique_index(:users, :email)
  end

end
