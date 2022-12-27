defmodule Nostr.Message do
  def parse(msg) when is_binary(msg), do: msg |> Jason.decode!(keys: :atoms) |> parse()

  # Client to relay
  def parse(["EVENT", event]) when is_map(event) do
    {:event, Nostr.Event.parse(event)}
  end

  def parse(["REQ", sub_id, filter]) when is_binary(sub_id) and is_map(filter) do
    {:req, sub_id, Nostr.Filter.parse(filter)}
  end

  def parse(["CLOSE", sub_id]) do
    {:close, sub_id}
  end

  # Relay to client
  def parse(["EVENT", sub_id, event]) when is_binary(sub_id) and is_map(event) do
    {:event, sub_id, Nostr.Event.parse(event)}
  end

  def parse(["NOTICE", message]) do
    {:notice, message}
  end

  def parse(["EOSE", sub_id]) do
    {:eose, sub_id}
  end

  def parse(message) do
    IO.inspect(message, label: "Unknown message")
  end
end
