defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.User do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :email, :string
      add :name, :string
      add :office_phone, :string
      add :cell_phone, :string
      add :encrypted_password, :string
      add :office_id, references(:offices, on_delete: :nothing)
      add :role_id, :integer
      add :email_sig, :text

      timestamps()
    end

    # alter table(:users) do
    #   modify(:id, :bigint)
    # end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])

  end
end
