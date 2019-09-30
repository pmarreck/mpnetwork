defmodule Mpnetwork.Ecto.CompressedTerm do
  @behaviour Ecto.Type
  alias :lz4, as: LZ4

  # The functionality below depends on the lz4_erl module.
  # Note that pack/unpack stores the decompressed data length as the first 4 bytes
  # or assumes those bytes are that value.
  # Additionally, in the event the compression scheme is changed, an 8 bit version_id
  # is prefixed in front of the binary, which is then pattern-matched on.

  # Version 1 - LZ4 compression @ high
  @current_version 1

  defp compress(txt, version \\ @current_version) when is_binary(txt) do
    {:ok, comp} = LZ4.pack(txt, [:high])
    <<version>> <> comp
  end

  defp decompress(<< 1, bin::binary >>) when is_binary(bin) do
    {:ok, decomp} = LZ4.unpack(bin)
    decomp
  end

  defp decompress(<< _bin::binary>>), do: raise "Unsupported compression version"

  def type, do: :binary

  def cast(term), do: {:ok, term}

  def load(binary) when is_binary(binary), do: {:ok, :erlang.binary_to_term(decompress(binary))}

  def dump(term), do: {:ok, compress(:erlang.term_to_binary(term))}
end
