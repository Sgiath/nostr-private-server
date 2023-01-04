defmodule Nostr.Event.Validator do
  @dialyzer {:no_return, valid_sig?: 1}

  def valid?(%Nostr.Event{} = event) do
    valid_id?(event) and valid_sig?(event)
  end

  defp valid_id?(%Nostr.Event{id: id} = event) do
    Nostr.Event.compute_id(event) == id
  end

  defp valid_sig?(%Nostr.Event{id: id, sig: sig, pubkey: pubkey}) do
    Secp256k1.schnorr_valid?(
      Base.decode16!(sig, case: :lower),
      Base.decode16!(id, case: :lower),
      Base.decode16!(pubkey, case: :lower)
    )
  end
end
