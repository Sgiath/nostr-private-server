defmodule Nostr do
  use DynamicSupervisor

  def test do
    {:ok, pid} = Nostr.Connection.start_link(url: "wss://relay.damus.io")
    Process.sleep(1000)
    Nostr.Connection.req(pid, %Nostr.Filter{since: 0}, "test")
  end

  def connected_relays do
    for {:undefined, pid, :worker, [_name]} <- DynamicSupervisor.which_children(Nostr) do
      GenServer.call(pid, :state)
    end
  end

  # Private API

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(url, read_only \\ false) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Nostr.Connection, [url: url, read_only: read_only]}
    )
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
