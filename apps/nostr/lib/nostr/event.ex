defmodule Nostr.Event do
  @moduledoc """
  Nostr Event
  """

  @dialyzer {:no_return, correct_sig?: 1}

  @enforce_keys [:id, :pubkey, :kind, :tags, :created_at, :content, :sig]
  defstruct id: nil, pubkey: nil, kind: nil, tags: [], created_at: nil, content: "", sig: nil

  @typedoc "Nostr event"
  @type t() :: %__MODULE__{
          id: <<_::32, _::_*8>>,
          pubkey: <<_::32, _::_*8>>,
          kind: non_neg_integer(),
          tags: [[String.t()]],
          created_at: DateTime.t(),
          content: String.t(),
          sig: <<_::64, _::_*8>>
        }

  def parse(event) when is_map(event) do
    if correct_id?(event) and correct_sig?(event) do
      %__MODULE__{
        id: event.id,
        pubkey: event.pubkey,
        kind: event.kind,
        tags: parse_tags(event.tags),
        created_at: DateTime.from_unix!(event.created_at),
        content: event.content,
        sig: event.sig
      }
    end
  end

  def parse_tags(tags) do
    Enum.map(tags, fn [type, data | rest] -> {String.to_atom(type), data, rest} end)
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
        created_at: DateTime.to_unix(event.created_at),
        content: event.content,
        sig: event.sig
      },
      opts
    )
  end
end
