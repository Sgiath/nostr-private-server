defmodule Client.Live.Nostr do
  use Client, :live_view

  @impl true
  def mount(_params, _args, socket) do
    {:ok, assign(socket, :relays, Nostr.connected_relays())}
  end

  @impl true
  def handle_event("connect", _value, socket) do
    Nostr.start_child("wss://relay.damus.io")

    {:noreply, assign(socket, :relays, Nostr.connected_relays())}
  end
end
