defmodule Mpnetwork.Repo.Migrations.AddDbConstraintsToReflectAllowedDatetimeValuesEnforcedBySchema do
  use Ecto.Migration

  @idempotent_deconstruction [
    "ALTER TABLE listings DROP CONSTRAINT IF EXISTS broker_oh_start_earlier_than_end;",
    "ALTER TABLE listings DROP CONSTRAINT IF EXISTS cust_oh_start_earlier_than_end;",
    "ALTER TABLE listings DROP CONSTRAINT IF EXISTS listing_date_earlier_than_expiry_date;",
    "ALTER TABLE listings DROP CONSTRAINT IF EXISTS broker_oh_datetimes_same_day;",
    "ALTER TABLE listings DROP CONSTRAINT IF EXISTS cust_oh_datetimes_same_day;",
  ]
  @enforce_initial_validity [
    "UPDATE listings SET next_broker_oh_end_at = next_broker_oh_start_at + interval '4 hours' WHERE next_broker_oh_start_at >= next_broker_oh_end_at;",
    "UPDATE listings SET next_cust_oh_end_at = next_cust_oh_start_at + interval '4 hours' WHERE next_cust_oh_start_at >= next_cust_oh_end_at;",
    "UPDATE listings SET expires_on = visible_on + interval '1 month' WHERE visible_on >= expires_on;",
    "UPDATE listings SET next_broker_oh_end_at = (next_broker_oh_start_at + interval '4 hours') WHERE NOT(EXTRACT(YEAR FROM next_broker_oh_start_at) = EXTRACT(YEAR FROM next_broker_oh_end_at) AND EXTRACT(DOY FROM next_broker_oh_start_at) = EXTRACT(DOY FROM next_broker_oh_end_at));",
    "UPDATE listings SET next_cust_oh_end_at = (next_cust_oh_start_at + interval '4 hours') WHERE NOT(EXTRACT(YEAR FROM next_cust_oh_start_at) = EXTRACT(YEAR FROM next_cust_oh_end_at) AND EXTRACT(DOY FROM next_cust_oh_start_at) = EXTRACT(DOY FROM next_cust_oh_end_at));",
  ]
  @implementation [
    "ALTER TABLE listings ADD CONSTRAINT broker_oh_start_earlier_than_end CHECK (next_broker_oh_start_at < next_broker_oh_end_at);",
    "ALTER TABLE listings ADD CONSTRAINT cust_oh_start_earlier_than_end CHECK (next_cust_oh_start_at < next_cust_oh_end_at);",
    "ALTER TABLE listings ADD CONSTRAINT listing_date_earlier_than_expiry_date CHECK (visible_on < expires_on);",
    "ALTER TABLE listings ADD CONSTRAINT broker_oh_datetimes_same_day CHECK (EXTRACT(YEAR FROM next_broker_oh_start_at) = EXTRACT(YEAR FROM next_broker_oh_end_at) AND EXTRACT(DOY FROM next_broker_oh_start_at) = EXTRACT(DOY FROM next_broker_oh_end_at));",
    "ALTER TABLE listings ADD CONSTRAINT cust_oh_datetimes_same_day CHECK (EXTRACT(YEAR FROM next_cust_oh_start_at) = EXTRACT(YEAR FROM next_cust_oh_end_at) AND EXTRACT(DOY FROM next_cust_oh_start_at) = EXTRACT(DOY FROM next_cust_oh_end_at));",
  ]

  def up do
    warn "WARNING: this constraint migration is destructive and will result in irreversible autocorrection of invalid datetime values"
    @idempotent_deconstruction ++ @enforce_initial_validity ++ @implementation
    |> Enum.each(fn statement ->
      execute statement
    end)
  end

  def down do
    warn "WARNING: Previously-invalid datetime values are irretrievable."
    @idempotent_deconstruction
    |> Enum.each(fn statement ->
      execute statement
    end)
  end

  defp warn(w) do
    IO.puts IO.ANSI.format [:red, :blink_slow, w]
  end

end
