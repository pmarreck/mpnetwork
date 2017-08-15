defmodule Mpnetwork.Repo.Migrations.AddEquestrianToListing do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :equestrian, :boolean
    end
  end
end
