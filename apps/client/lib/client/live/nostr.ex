defmodule Client.Live.Nostr do
  use Client, :live_view

  require Logger

  @impl true
  def mount(_params, _args, socket) do
    subs = Nostr.Client.get_subs()

    events =
      subs
      |> Enum.map(fn %{id: id} -> Nostr.Client.get_events(id) end)
      |> List.flatten()
      |> Enum.group_by(fn %{event: %Nostr.Event{kind: k}} -> k end)

    meta =
      events
      |> Map.get(0, [])
      |> Enum.sort(&Kernel.==(DateTime.compare(&1.event.created_at, &2.event.created_at), :gt))
      |> List.first(%{})

    following =
      events
      |> Map.get(3, [])
      |> Enum.filter(fn %Nostr.Event.Contacts{user: pubkey} ->
        pubkey == Client.Config.pubkey()
      end)
      |> Enum.map(fn %Nostr.Event.Contacts{contacts: c} -> c end)
      |> List.flatten()
      |> Enum.into(MapSet.new())

    notes =
      events
      |> Map.get(1, [])
      |> Enum.sort(fn %{event: %{created_at: c1}}, %{event: %{created_at: c2}} ->
        DateTime.compare(c1, c2) == :gt
      end)

    messages =
      events
      |> Map.get(4, [])
      |> Enum.sort(fn %{event: %{created_at: c1}}, %{event: %{created_at: c2}} ->
        DateTime.compare(c1, c2) == :gt
      end)
      |> Enum.map(&Nostr.Event.DirectMessage.decrypt(&1, Client.Config.seckey()))

    if connected?(socket) do
      pid = self()

      Nostr.Client.set_notice_handler(&send(pid, {:notice, &1, &2}))
      Nostr.Client.set_auth_handler(&send(pid, {:notice, &1, &2}))

      :timer.send_interval(500, pid, :update)
    end

    {:ok,
     assign(socket, %{
       relays: Nostr.Client.get_cons(),
       subscriptions: subs,
       metadata: meta,
       following: following,
       notes: notes,
       events: [],
       messages: messages
     })}
  end

  @impl true
  def handle_event("connect", _value, socket) do
    for url <- Client.Config.relays() do
      Nostr.Client.add_relay(url)
    end

    {:noreply, assign(socket, :relays, Nostr.Client.get_cons())}
  end

  def handle_event("disconnect", %{"url" => url}, socket) do
    Nostr.Client.disconnect_relay(url)

    {:noreply, assign(socket, :relays, Nostr.Client.get_cons())}
  end

  def handle_event("close-all", _value, socket) do
    for %{id: id} <- socket.assigns.subscriptions do
      Nostr.Client.close_sub(id)
    end

    {:noreply, assign(socket, :subscriptions, Nostr.Client.get_subs())}
  end

  def handle_event("close", %{"sub-id" => id}, socket) do
    Nostr.Client.close_sub(id)

    {:noreply, assign(socket, :subscriptions, Nostr.Client.get_subs())}
  end

  def handle_event("request", _value, socket) do
    filter1 = %Nostr.Filter{
      authors: [Client.Config.pubkey()],
      since: ~U[1970-01-01 00:00:00Z]
    }

    filter2 = %Nostr.Filter{
      "#p": [Client.Config.pubkey()],
      since: ~U[1970-01-01 00:00:00Z]
    }

    sub_id = 32 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)

    Nostr.Client.start_sub(sub_id, [filter1, filter2])

    {:noreply, assign(socket, :subscriptions, Nostr.Client.get_subs())}
  end

  def handle_event("request-profile", _value, socket) do
    filter = %Nostr.Filter{
      authors: [Client.Config.pubkey()],
      kinds: [0]
    }

    Nostr.Client.start_sub("profile", [filter])

    {:noreply, assign(socket, :subscriptions, Nostr.Client.get_subs())}
  end

  def handle_event("request-following", _value, socket) do
    filter = %Nostr.Filter{
      authors: [Client.Config.pubkey()],
      kinds: [3]
    }

    Nostr.Client.start_sub("following", [filter])

    {:noreply, assign(socket, :subscriptions, Nostr.Client.get_subs())}
  end

  def handle_event("request-notes", _value, socket) do
    my_notes = %Nostr.Filter{
      authors: [Client.Config.pubkey()],
      kinds: [1]
    }

    mentions = %Nostr.Filter{
      "#p": [Client.Config.pubkey()],
      kinds: [1]
    }

    Nostr.Client.start_sub("notes", [my_notes, mentions])

    {:noreply, assign(socket, :subscriptions, Nostr.Client.get_subs())}
  end

  def handle_event("request-messages", _value, socket) do
    my_messages = %Nostr.Filter{
      authors: [Client.Config.pubkey()],
      kinds: [4]
    }

    replies = %Nostr.Filter{
      "#p": [Client.Config.pubkey()],
      kinds: [4]
    }

    Nostr.Client.start_sub("messages", [my_messages, replies])

    {:noreply, assign(socket, :subscriptions, Nostr.Client.get_subs())}
  end

  @impl true
  # Handle metadata
  def handle_info(%Nostr.Event.Metadata{} = event, socket) do
    {:noreply, assign(socket, :metadata, event)}
  end

  # Handle note
  def handle_info(%Nostr.Event.Note{} = event, socket) do
    {:noreply, assign(socket, :notes, sort([event | socket.assigns.notes]))}
  end

  # Handle following
  def handle_info(%Nostr.Event.Contacts{user: p, contacts: c}, socket) do
    if p == Client.Config.pubkey() do
      f =
        MapSet.union(
          socket.assigns.following,
          MapSet.new(c)
        )

      {:noreply, assign(socket, :following, f)}
    else
      {:noreply, socket}
    end
  end

  # Handle encrypted message
  def handle_info(%Nostr.Event.DirectMessage{} = event, socket) do
    seckey = Client.Config.seckey()
    event = Nostr.Event.DirectMessage.decrypt(event, seckey)
    {:noreply, assign(socket, :messages, sort([event | socket.assigns.messages]))}
  end

  # Handle other events
  def handle_info(%{event: _event} = event, socket) do
    {:noreply, assign(socket, :events, sort([event | socket.assigns.events]))}
  end

  # Handle end of stream events
  def handle_info(:eose, socket) do
    {:noreply, socket}
  end

  # Handle end of stream events
  def handle_info({:notice, message, server}, socket) do
    Logger.warning("Received notice from server #{server}: #{message}")
    {:noreply, put_flash(socket, :warn, "#{message} from #{server}")}
  end

  def handle_info(:update, socket) do
    {:noreply,
     assign(socket, %{
       relays: Nostr.Client.get_cons(),
       subscriptions: Nostr.Client.get_subs()
     })}
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
