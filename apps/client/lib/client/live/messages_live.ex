defmodule Client.MessagesLive do
  use Client, :live_view

  def render(assigns) do
    ~H"""
    <%= for message <- @messages do %>
      <p><%= message.plain_text %></p>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    my_messages = %Nostr.Filter{
      authors: [Client.Config.pubkey()],
      kinds: [4]
    }

    replies = %Nostr.Filter{
      "#p": [Client.Config.pubkey()],
      kinds: [4]
    }

    Nostr.Client.start_sub("messages", [my_messages, replies])

    subs = Nostr.Client.get_subs()

    messages =
      subs
      |> Enum.map(fn %{id: id} -> Nostr.Client.get_events(id) end)
      |> List.flatten()
      |> Enum.filter(fn %{event: %Nostr.Event{kind: k}} -> k == 4 end)
      |> Enum.sort(fn %{event: %{created_at: c1}}, %{event: %{created_at: c2}} ->
        DateTime.compare(c1, c2) == :gt
      end)
      |> Enum.map(&Nostr.Event.DirectMessage.decrypt(&1, Client.Config.seckey()))

    {:ok, assign(socket, :messages, messages)}
  end

  def handle_info(%Nostr.Event.DirectMessage{} = event, socket) do
    seckey = Client.Config.seckey()
    event = Nostr.Event.DirectMessage.decrypt(event, seckey)
    {:noreply, assign(socket, :messages, sort([event | socket.assigns.messages]))}
  end

  defp sort(events) do
    events
    |> Enum.uniq_by(fn %{event: %Nostr.Event{id: id}} -> id end)
    |> Enum.sort(fn %{event: %Nostr.Event{created_at: c1}},
                    %{event: %Nostr.Event{created_at: c2}} ->
      DateTime.compare(c1, c2) == :gt
    end)
  end
end
