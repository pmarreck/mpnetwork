defmodule Mpnetwork.Repo.Migrations.ChangeFullnameToNameOnUsers do
  use Ecto.Migration

  def change do
  	rename table(:users), :fullname, to: :name
  end

end
