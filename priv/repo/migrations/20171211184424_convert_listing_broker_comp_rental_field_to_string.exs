defmodule Mpnetwork.Repo.Migrations.ConvertListingBrokerCompRentalFieldToString do
  use Ecto.Migration

  def up do
    alter table(:listings) do
      modify :listing_broker_comp_rental, :string
    end
  end

  def down do
    # these error with "column "section_num" cannot be cast automatically to type integer"
    # so I had to use executes (below)
    # alter table(:listings) do
    #   modify :listing_broker_comp_rental, :integer
    # end
    execute("ALTER TABLE listings ALTER COLUMN listing_broker_comp_rental TYPE integer USING (trim(listing_broker_comp_rental)::integer);")
  end
end
