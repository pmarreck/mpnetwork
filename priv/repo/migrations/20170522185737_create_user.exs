defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.User do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :email, :string
      add :fullname, :string
      add :firstname, :string
      add :lastname, :string
      add :office_phone, :string
      add :cell_phone, :string
      add :encrypted_password, :string
      add :office_id, :integer
      add :role_id, :integer

      timestamps()
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])

  end
end
