defmodule Nostr.Client.Connections do
  use DynamicSupervisor

  require Logger

  @child Nostr.Connection

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def children do
    for {:undefined, pid, :worker, [@child]} <- DynamicSupervisor.which_children(__MODULE__) do
      GenServer.call(pid, :state)
    end
  end

  def start_child(
        url,
        read_only \\ false,
        notice_handler \\ &Logger.error("Notice: #{&1} from #{&2}")
      ) do
    spec = {@child, url: url, read_only: read_only, notice_handler: notice_handler}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_child(url) do
    [{pid, nil}] = Registry.lookup(Nostr.Client.RelayRegistry, url)
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def set_notice_handler(handler) do
    for {:undefined, pid, :worker, [@child]} <- DynamicSupervisor.which_children(__MODULE__) do
      GenServer.cast(pid, {:notice_handler, handler})
    end

    :ok
  end
end
