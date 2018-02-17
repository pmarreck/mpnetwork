defmodule Mpnetwork.Repo.Migrations.RenameVisibleOnToLiveAtAndMakeDatetime do
  use Ecto.Migration

  def up do
    rename table(:listings), :visible_on, to: :live_at
    alter table(:listings) do
      modify :live_at, :utc_datetime
    end
    # this only works in EST
    execute "UPDATE listings SET live_at = (live_at + interval '5 hours')"
  end

  def down do
    # this only works in EST
    execute "UPDATE listings SET live_at = (live_at - interval '5 hours')"
    alter table(:listings) do
      modify :live_at, :date
    end
    rename table(:listings), :live_at, to: :visible_on
  end
end
