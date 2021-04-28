defmodule Mpnetwork.Ecto.CompressedTerm do
  @behaviour Ecto.Type
  alias :lz4, as: LZ4
  require Logger

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

  defp decompress(<<1, bin::binary>>) when is_binary(bin) do
    case LZ4.unpack(bin) do
      {:ok, decomp} -> decomp
      # So on error here we don't throw because this is run during database accesses and that would be bad,
      # especially considering this is currently only used on *session data*.
      # For now, we just return an empty string.
      # But we DO log it.
      # And we only log a code in case this is happening thousands of times a second.
      # If you searched the code for that... code, then you should be reading this!
      {:error, :uncompress_failed} -> 
        Logger.error("CT_error_69") # Corrupt data in a v1 CompressedTerm field resulted in a failed decompression
        :erlang.term_to_binary("")
      {:error, reason} ->
        Logger.error("CT_error_70: #{inspect reason}") # Decompression of a CompressedTerm failed for unknown reasons
        :erlang.term_to_binary("")
    end
  end

  defp decompress(<<_bin::binary>>), do: raise("Unsupported compression version")

  def type, do: :binary

  def cast(term), do: {:ok, term}

  def load(binary) when is_binary(binary), do: {:ok, :erlang.binary_to_term(decompress(binary))}

  def dump(term), do: {:ok, compress(:erlang.term_to_binary(term))}

  # :dump is the other option
  def embed_as(_), do: :self

  def equal?(term1, term2), do: term1 == term2
end
