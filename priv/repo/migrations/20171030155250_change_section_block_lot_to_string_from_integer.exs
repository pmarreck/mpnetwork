defmodule Mpnetwork.Repo.Migrations.ChangeSectionBlockLotToStringFromInteger do
  use Ecto.Migration

  def up do
    alter table(:listings) do
      modify :section_num, :string
      modify :block_num, :string
      modify :lot_num, :string
    end
  end

  def down do
    alter table(:listings) do
      modify :section_num, :integer
      modify :block_num, :integer
      modify :lot_num, :integer
    end
  end

end
