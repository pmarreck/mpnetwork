defmodule Mpnetwork.Crypto do

  @key (System.get_env("BUBBLES") || "VZiqNo1uZRyC1AHm2AhjWpaMuVl84KTQoGhDFZQbJ0w") |> Base.decode64!(padding: false)

  def encrypt(data) do
    cleartext = :erlang.term_to_binary(data)
    {:ok, {iv, ciphertext}} = ExCrypto.encrypt(@key, cleartext)
    Base.url_encode64(iv <> ciphertext, padding: false)
  end

  def decrypt(ciphertext) do
    <<iv::binary-16, ciphertext::binary>> = Base.url_decode64!(ciphertext, padding: false)
    {:ok, cleartext} = ExCrypto.decrypt(@key, iv, ciphertext)
    :erlang.binary_to_term(cleartext)
  end

end
