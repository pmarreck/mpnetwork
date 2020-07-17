defmodule Mpnetwork.Repo.Migrations.AddAddlColistingAgentAndAddlColistingAgentPhoneAndAddlColistingBrokerToListing do
  use Ecto.Migration

  def up do
    alter table(:listings) do
      add_if_not_exists :addl_listing_agent_name, :string
      add_if_not_exists :addl_listing_agent_phone, :string
      add_if_not_exists :addl_listing_broker_name, :string
    end
  end
  def down do
    IO.puts "#{IO.ANSI.blink_slow()}WARNING#{IO.ANSI.blink_off()}: The listing_search_update trigger will be cascade-deleted by this and will need to be recreated/rerun if necessary!"
    [
      "ALTER TABLE listings DROP COLUMN IF EXISTS addl_listing_agent_name CASCADE",
      "ALTER TABLE listings DROP COLUMN IF EXISTS addl_listing_agent_phone CASCADE",
      "ALTER TABLE listings DROP COLUMN IF EXISTS addl_listing_broker_name CASCADE"
    ]
    |> Enum.each(fn stmt -> execute(stmt) end)
  end
end
