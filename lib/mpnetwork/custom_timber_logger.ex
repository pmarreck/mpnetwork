defmodule Mpnetwork.CustomTimberLogger do
  # The point of this module is to truncate query log entries at 4096 to fix an issue where
  # those wouldn't get logged by Timber due to exceeding length of 4096.

  alias Timber.Integrations.EctoLogger, as: TimberLogger

  # Source for their logger, for reference:
  # https://github.com/timberio/timber-elixir/blob/master/lib/timber/integrations/ecto_logger.ex

  @spec log(Ecto.LogEntry.t()) :: Ecto.LogEntry.t()
  def log(event) do
    log(event, :debug)
  end

  @spec log(Ecto.LogEntry.t(), atom) :: Ecto.LogEntry.t()
  def log(%Ecto.LogEntry{query: query, query_time: time_native} = entry, level)
      when is_function(query) do
    log(%Ecto.LogEntry{query: query.(entry), query_time: time_native}, level)
  end

  @spec log(Ecto.LogEntry.t(), atom) :: Ecto.LogEntry.t()
  def log(%Ecto.LogEntry{query: query, query_time: time_native} = _entry, level)
      when is_binary(query) do
    TimberLogger.log(
      %Ecto.LogEntry{query: transform_log_entry(query), query_time: time_native},
      level
    )
  end

  defp transform_log_entry(query) when is_binary(query) do
    String.slice(query, 0, 4000)
  end
end
