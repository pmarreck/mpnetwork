defmodule Mpnetwork.CryptoTest do
  use ExUnit.Case, async: true
  alias Mpnetwork.Crypto

  # @aes_256_key "VZiqNo1uZRyC1AHm2AhjWpaMuVl84KTQoGhDFZQbJ0w" |> Base.decode64!(padding: false)
  @cleartext "this is a test"

  test "encrypt does not produce an empty string" do
    assert "" != Crypto.encrypt(@cleartext)
  end

  test "encrypt does not produce cleartext" do
    assert @cleartext != Crypto.encrypt(@cleartext)
  end

  test "decryption works on existing encrypted data" do
    assert @cleartext == Crypto.decrypt("4PE9G0H3jJnoU5xJNsJhdy6NCq-76V8Q82S6Hy2FcR0GkhqiNPhRAB5z-Fp1VKm8")
  end

  test "roundtrip through crypto wrapper library Just Works" do
    assert @cleartext == Crypto.decrypt(Crypto.encrypt(@cleartext))
  end

end
