defmodule Mpnetwork.Crypto do

  # This library originally was a wrapper around ex_crypto (which was itself also a wrapper, sigh)
  # With OTP24, ex_crypto wasn't getting updated and its internal calls to erlang's :crypto were deprecated.
  # So I imported its core code and updated it to use the new :crypto API here, and added tests.

  @aes_block_size 16
  @iv_bit_length 128

  # AES-256 key, base64-encoded
  @key (System.get_env("BUBBLES") || "VZiqNo1uZRyC1AHm2AhjWpaMuVl84KTQoGhDFZQbJ0w")
       |> Base.decode64!(padding: false)

  @doc """
  Returns a string of random bytes where the length is equal to `integer`.

  ## Examples

      iex> {:ok, rand_bytes} = rand_bytes(16)
      iex> assert(byte_size(rand_bytes) == 16)
      true
      iex> assert(bit_size(rand_bytes) == 128)
      true

      iex> {:ok, rand_bytes} = rand_bytes(24)
      iex> assert(byte_size(rand_bytes) == 24)
      true
      iex> assert(bit_size(rand_bytes) == 192)
      true

      iex> {:ok, rand_bytes} = rand_bytes(32)
      iex> assert(byte_size(rand_bytes) == 32)
      true
      iex> assert(bit_size(rand_bytes) == 256)
      true
  """
  @spec rand_bytes(integer) :: {:ok, binary} | {:error, binary}
  def rand_bytes(length) do
    {:ok, :crypto.strong_rand_bytes(length)}
  catch
    kind, error -> 
      case Exception.normalize(kind, error) do
        %{message: message} ->
          {:error, message}
        x ->
          {kind, x, __STACKTRACE__}
      end
  end

  @spec rand_bytes!(integer) :: binary
  def rand_bytes!(length) do
    case rand_bytes(length) do
      {:ok, data} -> data
      {:error, reason} -> raise reason
    end
  end

  def pad(data, block_size \\ @aes_block_size) do
    to_add = block_size - rem(byte_size(data), block_size)
    data <> :binary.copy(<<to_add>>, to_add)
  end

  def unpad(data) do
    to_remove = :binary.last(data)
    :binary.part(data, 0, byte_size(data) - to_remove)
  end

  def encrypt(data, key \\ @key) do
    padded_cleartext = pad(:erlang.term_to_binary(data))
    {:ok, {iv, ciphertext}} = _encrypt(key, padded_cleartext)
    Base.url_encode64(iv <> ciphertext, padding: false)
  end

  def decrypt(iv_ciphertext_b64, key \\ @key) do
    <<iv::binary-16, ciphertext::binary>> = Base.url_decode64!(iv_ciphertext_b64, padding: false)
    {:ok, padded_cleartext} = _decrypt(key, iv, ciphertext)
    cleartext = unpad(padded_cleartext)
    :erlang.binary_to_term(cleartext)
  end

  defp _encrypt(key, encryption_payload) do
    # new 128 bit random initialization_vector
    {:ok, initialization_vector} = rand_bytes(16)
    _encrypt(key, initialization_vector, encryption_payload)
  end
    
  defp _encrypt(key, initialization_vector, encryption_payload, algorithm \\ :aes_256_cbc) do
    # case :crypto.block_encrypt(algorithm, key, initialization_vector, encryption_payload) do
    case :crypto.crypto_one_time(algorithm, key, initialization_vector, encryption_payload, true) do
      {cipher_text, cipher_tag} ->
        {authentication_data, _clear_text} = encryption_payload
        raise {:ok, {authentication_data, {initialization_vector, cipher_text, cipher_tag}}}

      <<cipher_text::binary>> ->
        {:ok, {initialization_vector, cipher_text}}

      x ->
        {:error, x}
    end
  end

  defp _decrypt(key, initialization_vector, cipher_data, algorithm \\ :aes_256_cbc) do
    # case :crypto.block_decrypt(algorithm, key, initialization_vector, cipher_data) do
    case :crypto.crypto_one_time(algorithm, key, initialization_vector, cipher_data, false) do
      :error -> {:error, :decrypt_failed}
      plain_text -> {:ok, plain_text}
    end
  catch
    kind, error -> normalize_error(kind, error)
  end

  defp normalize_error(kind, error, key_and_iv \\ nil) do
    key_error = test_key_and_iv_bitlength(key_and_iv)

    normalized_result = Exception.normalize(kind, error)

    cond do
      key_error ->
        key_error

      %{term: %{message: message}} = normalized_result ->
        {:error, message}

      %{message: message} = normalized_result ->
        {:error, message}

      x = Exception.normalize(kind, error) ->
        {kind, x, Process.info(self(), :current_stacktrace)}
    end
  end

  @iv_bit_length 128
  @bitlength_error "IV must be exactly 128 bits and key must be exactly 128, 192 or 256 bits"
  defp test_key_and_iv_bitlength(nil), do: nil
  defp test_key_and_iv_bitlength({_key, iv}) when bit_size(iv) != @iv_bit_length,
    do: {:error, @bitlength_error}
  defp test_key_and_iv_bitlength({key, _iv}) when rem(bit_size(key), 128) == 0, do: nil
  defp test_key_and_iv_bitlength({key, _iv}) when rem(bit_size(key), 192) == 0, do: nil
  defp test_key_and_iv_bitlength({key, _iv}) when rem(bit_size(key), 256) == 0, do: nil
  defp test_key_and_iv_bitlength({_key, _iv}), do: {:error, @bitlength_error}

end
