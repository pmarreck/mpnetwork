defmodule Mpnetwork.Repo.Migrations.AddNewListingEmailUserPref do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pref_new_listing_email, :boolean
    end
    create index(:users, [:pref_new_listing_email])
  end

end
