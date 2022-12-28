defmodule Nostr.Event do
  @moduledoc """
  Nostr Event
  """

  defstruct [:id, :pubkey, :kind, :tags, :created_at, :content, :sig]

  def parse(event) when is_map(event) do
    if correct_id?(event) and correct_sig?(event) do
      %__MODULE__{
        id: event.id,
        pubkey: event.pubkey,
        kind: event.kind,
        tags: event.tags,
        created_at: event.created_at,
        content: event.content,
        sig: event.sig
      }
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
    Jason.encode!([0, pubkey, created_at, kind, tags, content])
  end
end

defimpl Jason.Encoder, for: Nostr.Event do
  def encode(%Nostr.Event{} = event, opts) do
    Jason.Encode.map(
      %{
        id: event.id,
        pubkey: event.pubkey,
        kind: event.kind,
        tags: event.tags,
        created_at: event.created_at,
        content: event.content,
        sig: event.sig
      },
      opts
    )
  end
end
