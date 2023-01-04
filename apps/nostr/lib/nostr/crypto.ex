defmodule Nostr.Crypto do
  @moduledoc """
  Crypto related stuff
  """

  @dialyzer {:no_return, encrypt: 3, decrypt: 3, shared_secret: 2}
  @dialyzer {:no_unused, d64: 1, e64: 1}

  def encrypt(message, seckey, pubkey) do
    iv = :crypto.strong_rand_bytes(16)

    cipher_text =
      :crypto.crypto_one_time(:aes_256_cbc, shared_secret(seckey, pubkey), iv, message,
        encrypt: true,
        padding: :pkcs_padding
      )

    e64(cipher_text) <> "?iv=" <> e64(iv)
  end

  def decrypt(message, seckey, pubkey) do
    [message, iv] = String.split(message, "?iv=")

    :crypto.crypto_one_time(:aes_256_cbc, shared_secret(seckey, pubkey), d64(iv), d64(message),
      encrypt: false
      # padding: :pkcs_padding
    )
  end

  defp shared_secret(seckey, pubkey) when is_binary(seckey) and is_binary(pubkey) do
    Secp256k1.ecdh(d16(seckey), <<0x02::size(8), d16(pubkey)::binary>>)
  end

  defp d16(data), do: Base.decode16!(data, case: :lower)
  defp d64(data), do: Base.decode64!(data)

  # defp e16(data), do: Base.encode16(data, case: :lower)
  defp e64(data), do: Base.encode64(data)
end
