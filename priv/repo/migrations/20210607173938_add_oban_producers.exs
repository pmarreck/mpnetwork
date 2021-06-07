defmodule Mpnetwork.Repo.Migrations.AddObanProducers do
  use Ecto.Migration

  defdelegate change, to: Oban.Pro.Migrations.Producers
end
