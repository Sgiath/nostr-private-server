defmodule Nostr.Event do
  def parse(event) do
    if correct_id?(event) and correct_sig?(event) do
      event
    end
  end

  def correct_id?(%{id: id} = event) do
    compute_id(event) == id
  end

  def correct_sig?(%{id: id, sig: sig, pubkey: pubkey}) do
    Secp256k1.schnorr_valid?(
      Base.decode16!(sig, case: :lower),
      Base.decode16!(id, case: :lower),
      Base.decode16!(pubkey, case: :lower)
    )
  end

  def compute_id(event) do
    :sha256
    |> :crypto.hash(serialize(event))
    |> Base.encode16(case: :lower)
  end

  def serialize(%{
        pubkey: pubkey,
        kind: kind,
        tags: tags,
        created_at: created_at,
        content: content
      }) do
    Jason.encode!([
      0,
      pubkey,
      created_at,
      kind,
      tags,
      content
    ])
  end
end
