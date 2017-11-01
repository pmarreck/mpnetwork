defmodule Mpnetwork.Repo.Migrations.AddSeparateRoundRobinRemarksToListingAndRenameRemarksToRealtorRemarks do
  use Ecto.Migration

  def change do
    rename table(:listings), :remarks, to: :realtor_remarks
    alter table(:listings) do
      add :round_robin_remarks, :text
    end
  rescue
    err -> nil
  end

end
