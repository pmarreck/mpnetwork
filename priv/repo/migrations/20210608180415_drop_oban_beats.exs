defmodule Mpnetwork.Repo.Migrations.DropObanBeats do
  use Ecto.Migration

  def up do
    drop_if_exists table("oban_beats")
    Oban.Migrations.up()
  end

  def down do
    # No going back!
    raise "Can't restore oban_beats table"
  end
end