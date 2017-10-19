defmodule Mpnetwork.Repo.Migrations.AddUrlToUserAndOffice do
  use Ecto.Migration

  def change do

    alter table(:users) do
      add :url, :string
    end

    alter table(:offices) do
      add :url, :string
    end

  end

end
