defmodule Mpnetwork.Repo.Migrations.RemoveConfirmableFieldsFromUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :confirmation_token
      remove :confirmed_at
      remove :confirmation_sent_at
    end
  end

  def down do
    alter table(:users) do
      add :confirmation_token, :string
      add :confirmed_at, :utc_datetime
      add :confirmation_sent_at, :utc_datetime
    end
  end
end
