defmodule Nostr.Event.Parser do
  def parse(event) when is_binary(event) do
    event
    |> Jason.decode!(keys: :atoms)
    |> parse()
  end

  def parse(event) when is_map(event) do
    %Nostr.Event{
      id: event.id,
      pubkey: event.pubkey,
      kind: event.kind,
      tags: Enum.map(event.tags, &Nostr.Tag.parse/1),
      created_at: DateTime.from_unix!(event.created_at),
      content: event.content,
      sig: event.sig
    }
  end
end
