defmodule Mpnetwork.Repo.Migrations.UpdateUserAddOfficesAndEmailSig do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :office_id
      add :office_id, references(:offices, on_delete: :nothing)
      add :email_sig, :text
    end
  end

  def down do
    alter table(:users) do
      remove :office_id
      add :office_id, :integer
      remove :email_sig
    end
  end
end
