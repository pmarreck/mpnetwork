defmodule Mpnetwork.Upload do
  alias Mpnetwork.Upload
  require ExImageInfo

  defstruct [:content_type, :filename, :binary]

  def normalize_plug_upload(%Plug.Upload{path: binary_data_loc} = pu) do
    data = File.read!(binary_data_loc)
    Enum.into(%{content_type: pu.content_type, filename: pu.filename}, %Upload{binary: data})
  end

  def normalize_plug_upload(%Upload{} = mu) do
    mu
  end

  def normalize_plug_upload(pu) when is_binary(pu) do
    %Upload{binary: pu}
  end

  def is_image?(content_type) do
    # note that these are all (and the only, currently) image types that ExImageInfo recognizes
    case content_type do
      "image/jpeg" -> true
      "image/gif" -> true
      "image/png" -> true
      "image/bmp" -> true
      "image/psd" -> true
      "image/tiff" -> true
      "image/webp" -> true
      _ -> false
    end
  end

  def sha256_hash(binary_data) do
    :crypto.hash(:sha256, binary_data)
  end

  def extract_meta_from_binary_data(binary_data, claimed_content_type) do
    case ExImageInfo.info(binary_data) do
      nil -> {claimed_content_type, nil, nil}
      {a, b, c, _} -> {a, b, c}
    end
  end
end

# stolen from the collectable implementation for Map
defimpl Collectable, for: Mpnetwork.Upload do
  def into(original) do
    {original,
     fn
       map, {:cont, {k, v}} -> :maps.put(k, v, map)
       map, :done -> map
       _, :halt -> :ok
     end}
  end
end
