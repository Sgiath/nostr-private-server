defmodule Nostr.Connection do
  use WebSockex

  require Logger

  def start_link(opts) do
    opts
    |> Keyword.get(:url)
    |> WebSockex.start_link(__MODULE__, %{
      read_only: Keyword.get(opts, :read_only, false),
      connections: MapSet.new()
    })
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected!")
    {:ok, state}
  end

  def handle_disconnect(_conn, state) do
    Logger.info("Disconnected!")
    {:reconnect, state}
  end

  def handle_frame({:text, msg}, state) do
    IO.inspect(state)
    message = Nostr.Message.parse(msg)
    IO.inspect(message)
    {:ok, state}
  end

  def handle_frame({type, msg}, state) do
    IO.puts("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    {:ok, state}
  end

  def handle_cast({:req, sub_id, filter}, state) do
    {:reply, {:text, Jason.encode!(["REQ", sub_id, filter])},
     Map.update!(state, :connections, &MapSet.put(&1, sub_id))}
  end

  def handle_cast({:close, sub_id}, state) do
    {:reply, {:text, Jason.encode!(["CLOSE", sub_id])},
     Map.update!(state, :connections, &MapSet.delete(&1, sub_id))}
  end

  def terminate(_reason, %{connections: cons}) do
    for c <- cons do
      WebSockex.cast(self(), {:close, c})
    end
  end
end
