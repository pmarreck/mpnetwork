defmodule Mpnetwork.Utils.Debugging do
  def i(thing) do
    IO.inspect(thing, limit: 100_000, printable_limit: 100_000, pretty: true)
  end
end
