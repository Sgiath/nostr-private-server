defmodule Nostr do
  @moduledoc """
  Nostr supervisor for holding connections
  """
  use DynamicSupervisor

  def event(%Nostr.Event{} = event) do
    event
    |> Nostr.Message.create_event()
    |> Nostr.Message.serialize()
    |> send()
  end

  def req(filter, sub_id) do
    filter
    |> Nostr.Message.request(sub_id)
    |> Nostr.Message.serialize()
    |> send()
  end

  def close(sub_id) do
    sub_id
    |> Nostr.Message.close()
    |> Nostr.Message.serialize()
    |> send()
  end

  def send(msg) do
    for {:undefined, pid, :worker, [_name]} <- DynamicSupervisor.which_children(__MODULE__) do
      GenServer.cast(pid, {:send, msg})
    end
  end

  @doc """
  Add connection to server
  """
  def add_server(url, read_only \\ false) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Nostr.Connection, [url: url, read_only: read_only]}
    )
  end

  @doc """
  Get all the connections
  """
  def connected_relays do
    for {:undefined, pid, :worker, [_name]} <- DynamicSupervisor.which_children(__MODULE__) do
      GenServer.call(pid, :state)
    end
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
