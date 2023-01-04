defmodule Nostr.Event do
  @moduledoc """
  Nostr Event
  """

  alias Nostr.Event.Parser
  alias Nostr.Event.Validator

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
    event = Parser.parse(event)

    if Validator.valid?(event), do: event
  end

  def compute_id(event) do
    :sha256
    |> :crypto.hash(serialize(event))
    |> Base.encode16(case: :lower)
  end

  def serialize(%__MODULE__{
        pubkey: pubkey,
        kind: kind,
        tags: tags,
        created_at: created_at,
        content: content
      }) do
    Jason.encode!([0, pubkey, DateTime.to_unix(created_at), kind, tags, content])
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
