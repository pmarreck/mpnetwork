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
    # these error with "column "section_num" cannot be cast automatically to type integer"
    # so I had to use executes (below)
    # alter table(:listings) do
    #   modify :section_num, :integer
    #   modify :block_num, :integer
    #   modify :lot_num, :integer
    # end
    execute("ALTER TABLE listings ALTER COLUMN section_num TYPE integer USING (trim(section_num)::integer);")
    execute("ALTER TABLE listings ALTER COLUMN block_num TYPE integer USING (trim(block_num)::integer);")
    execute("ALTER TABLE listings ALTER COLUMN lot_num TYPE integer USING (trim(lot_num)::integer);")
  end

end
