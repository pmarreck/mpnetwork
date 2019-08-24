defmodule Mpnetwork.Ecto.CompressedTerm do
  @behaviour Ecto.Type

  # The functionality below depends on the lz4_erl module.
  # Note that pack/unpack stores the decompressed data length as the first 4 bytes
  # or assumes those bytes are that value

  defp compress(txt) when is_binary(txt) do
    {:ok, comp} = :lz4.pack(txt, [:high])
    comp
  end

  defp decompress(bin) when is_binary(bin) do
    {:ok, decomp} = :lz4.unpack(bin)
    decomp
  end

  def type, do: :binary

  def cast(term), do: {:ok, term}

  def load(binary) when is_binary(binary), do: {:ok, :erlang.binary_to_term(decompress(binary))}

  def dump(term), do: {:ok, compress(:erlang.term_to_binary(term))}
end
