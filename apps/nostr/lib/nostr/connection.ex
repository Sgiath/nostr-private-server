defmodule Nostr.Connection do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # Nostr requests

  def event(pid, %Nostr.Event{} = event) do
    msg =
      event
      |> Nostr.Message.create_event()
      |> Nostr.Message.serialize()

    GenServer.cast(pid, {:send, msg})
  end

  def req(pid, filter, sub_id) do
    msg =
      filter
      |> Nostr.Message.request(sub_id)
      |> Nostr.Message.serialize()

    GenServer.cast(pid, {:send, msg})
  end

  def close(pid, sub_id) do
    msg =
      sub_id
      |> Nostr.Message.close()
      |> Nostr.Message.serialize()

    GenServer.cast(pid, {:send, msg})
  end

  # Private API

  @impl GenServer
  def init(opts) do
    url = opts |> Keyword.fetch!(:url) |> URI.parse()
    read_only = Keyword.get(opts, :read_only, false)

    port =
      case url do
        %URI{scheme: "wss", port: port} -> port || 443
        %URI{scheme: "ws", port: port} -> port || 80
      end

    # Establish WebSocket connection
    {:ok, conn} =
      :gun.open(String.to_charlist(url.host), port, %{
        protocols: [:http],
        tls_opts: [verify: :verify_none]
      })

    {:ok, %{conn: conn, stream: nil, url: url, read_only: read_only}}
  end

  @impl GenServer
  def handle_cast({:send, msg}, state) do
    :gun.ws_send(state.conn, state.stream, {:text, msg})
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_info({:gun_up, conn, :http}, state) do
    Logger.debug("Connection up #{state.url.host}")
    stream = :gun.ws_upgrade(conn, state.url.path || "/")
    {:noreply, %{state | conn: conn, stream: stream}}
  end

  def handle_info({:gun_upgrade, _conn, _stream, ["websocket"], _headers}, state) do
    Logger.debug("WebSocket upgraded #{state.url.host}")
    {:noreply, state}
  end

  def handle_info({:gun_response, _conn, _stream, _fin, status, _headers}, state) do
    Logger.warning("Response #{status} #{state.url.host}")
    {:noreply, state}
  end

  def handle_info({:gun_data, _conn, _stream, _fin, _response}, state) do
    {:noreply, state}
  end

  def handle_info({:gun_down, _conn, :http, :closed, _headers}, state) do
    Logger.warning("HTTP connection down #{state.url.host}")
    {:noreply, state}
  end

  def handle_info({:gun_down, _conn, :ws, :closed, _headers}, state) do
    Logger.warning("WebSocket connection down #{state.url.host}")
    {:noreply, state}
  end

  def handle_info({:gun_ws, _conn, _stream, {:text, message}}, state) do
    Logger.debug("Message received")

    message
    |> Nostr.Message.parse()
    |> case do
      {:event, sub_id, event} ->
        Phoenix.PubSub.broadcast(Nostr.PubSub, "events:#{state.url.host}:#{sub_id}", event)

      {:eose, sub_id} ->
        Phoenix.PubSub.broadcast(Nostr.PubSub, "events:#{state.url.host}:#{sub_id}", :eose)

      {:notice, message} ->
        Phoenix.PubSub.broadcast(Nostr.PubSub, "relays:#{state.url.host}", message)
    end

    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    :gun.shutdown(state.conn)
  end
end
