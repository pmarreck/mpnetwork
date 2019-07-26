defmodule Mpnetwork.Ecto.Term do
  @behaviour Ecto.Type

  def type, do: :binary

  def cast(term), do: {:ok, term}

  def load(binary) when is_binary(binary), do: {:ok, :erlang.binary_to_term(binary)}

  def dump(term), do: {:ok, :erlang.term_to_binary(term)}
end
