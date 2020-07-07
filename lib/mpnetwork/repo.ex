defmodule Mpnetwork.Repo do
  use Ecto.Repo, otp_app: :mpnetwork, adapter: Ecto.Adapters.Postgres

  alias Ecto.{Adapters.SQL, Multi}

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  EDIT: 6/19/2019: moved back to env config which THEN reads from the right environment variable.
  """
  def init(_, opts) do
    {:ok, opts}
  end

  # the source key can either have a tuple of {prefix, table} or just the table name string
  defp table_for(%{__meta__: %{source: {schema_prefix, source}}}) when is_binary(source),
    do: {schema_prefix, source}

  defp table_for(%{__meta__: %{source: source}}) when is_binary(source), do: {:public, source}

  def hard_delete(struct) do
    {prefix, table} = table_for(struct)

    # note: I had a deadlock on this multi once in a test, could not duplicate it with same seed (49866).
    # Perhaps review in future.
    Multi.new()
    |> Multi.run(:disable_after_delete_trigger, fn repo, _ ->
      query = "ALTER TABLE #{prefix}.#{table} DISABLE TRIGGER #{table}_logical_delete_tg;"
      SQL.query(repo, query)
    end)
    |> Multi.delete(:delete, struct)
    |> Multi.run(:enable_after_delete_trigger, fn repo, _ ->
      query = "ALTER TABLE #{prefix}.#{table} ENABLE TRIGGER #{table}_logical_delete_tg;"
      SQL.query(repo, query)
    end)
    |> transaction()
  end
end
