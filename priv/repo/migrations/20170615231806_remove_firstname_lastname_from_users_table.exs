defmodule Mpnetwork.Repo.Migrations.RemoveFirstnameLastnameFromUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :firstname
      remove :lastname
    end
  end
end
