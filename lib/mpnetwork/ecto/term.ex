defmodule Mpnetwork.Ecto.Term do
  @behaviour Ecto.Type

  def type, do: :binary

  def cast(term), do: {:ok, term}

  def load(binary) when is_binary(binary), do: {:ok, :erlang.binary_to_term(binary)}

  def dump(term), do: {:ok, :erlang.term_to_binary(term)}

  # :dump is the other option
  def embed_as(_), do: :self

  def equal?(term1, term2), do: term1 == term2
end
