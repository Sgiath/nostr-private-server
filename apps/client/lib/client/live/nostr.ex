defmodule Client.Live.Nostr do
  use Client, :live_view

  require Logger

  @impl true
  def mount(_params, _args, socket) do
    Phoenix.PubSub.subscribe(Nostr.PubSub, "events:test")

    {:ok,
     assign(socket, %{
       relays: Nostr.connected_relays(),
       metadata: %{},
       following: MapSet.new(),
       notes: [],
       events: [],
       messages: []
     })}
  end

  @impl true
  def handle_event("connect", _value, socket) do
    for url <- Client.Config.relays() do
      {:ok, pid} = Nostr.add_server(url)
      state = GenServer.call(pid, :state)
      Phoenix.PubSub.subscribe(Nostr.PubSub, "relays:#{state.url.host}")
    end

    {:noreply, assign(socket, :relays, Nostr.connected_relays())}
  end

  def handle_event("disconnect", _value, socket) do
    for {:undefined, pid, :worker, [_name]} <- DynamicSupervisor.which_children(Nostr) do
      DynamicSupervisor.terminate_child(Nostr, pid)
    end

    {:noreply, assign(socket, :relays, Nostr.connected_relays())}
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

    Nostr.req([filter1, filter2], sub_id)
    Phoenix.PubSub.subscribe(Nostr.PubSub, "events:#{sub_id}")

    {:noreply, assign(socket, :relays, Nostr.connected_relays())}
  end

  @impl true
  # Handle metadata
  def handle_info(%Nostr.Event{kind: 0, content: content}, socket) do
    {:noreply, assign(socket, :metadata, Jason.decode!(content))}
  end

  # Handle note
  def handle_info(%Nostr.Event{kind: 1} = event, socket) do
    {:noreply, assign(socket, :notes, sort([event | socket.assigns.notes]))}
  end

  # Handle following
  def handle_info(%Nostr.Event{pubkey: p, kind: 3, tags: tags}, socket) do
    if p == Client.Config.pubkey() do
      f =
        MapSet.union(
          socket.assigns.following,
          tags |> Enum.map(&elem(&1, 1)) |> Enum.into(MapSet.new())
        )

      {:noreply, assign(socket, :following, f)}
    else
      {:noreply, socket}
    end
  end

  # Handle encrypted message
  def handle_info(
        %Nostr.Event{pubkey: pubkey, kind: 4, content: content, tags: tags} = event,
        socket
      ) do
    seckey = Client.Config.seckey()
    my_pubkey = Client.Config.pubkey()

    pubkey =
      if pubkey == my_pubkey do
        Enum.find_value(tags, fn
          {:p, pubkey, []} -> pubkey
          _ -> false
        end)
      else
        pubkey
      end

    event =
      Map.put(event, :content, %{
        cipher_text: content,
        plain_text: Nostr.Crypto.decrypt(content, seckey, pubkey)
      })

    {:noreply, assign(socket, :messages, sort([event | socket.assigns.messages]))}
  end

  # Handle other events
  def handle_info(%Nostr.Event{} = event, socket) do
    {:noreply, assign(socket, :events, sort([event | socket.assigns.events]))}
  end

  # Handle end of stream events
  def handle_info(:eose, socket) do
    {:noreply, socket}
  end

  # Handle end of stream events
  def handle_info({:notice, message, server}, socket) do
    Logger.warning("Received notice from server #{server}: #{message}")
    {:noreply, socket}
  end

  defp sort(events) do
    events
    |> Enum.uniq_by(fn %Nostr.Event{id: id} -> id end)
    |> Enum.sort(fn %Nostr.Event{created_at: c1}, %Nostr.Event{created_at: c2} ->
      DateTime.compare(c1, c2) == :gt
    end)
  end
end
