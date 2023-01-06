defmodule Nostr.Client.Subscriptions do
  use DynamicSupervisor

  require Logger

  @child Nostr.Subscription

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

  def start_child(id, filters, relays \\ :all)

  def start_child(id, filters, :all) do
    relays = Enum.map(Nostr.Client.get_cons(), & &1.url)
    spec = {@child, id: id, filters: filters, relays: relays, subscribers: [self()]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def start_child(id, filters, relays) do
    spec = {@child, id: id, filters: filters, relays: relays, subscribers: [self()]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_child(id) do
    [{pid, nil}] = Registry.lookup(Nostr.Client.SubscriptionRegistry, id)
    GenServer.call(pid, :close)
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def subscribe(id, s_pid) do
    [{pid, nil}] = Registry.lookup(Nostr.Client.SubscriptionRegistry, id)
    GenServer.cast(pid, {:subscribe, s_pid})
  end

  def events(id) do
    [{pid, nil}] = Registry.lookup(Nostr.Client.SubscriptionRegistry, id)
    GenServer.call(pid, :events)
  end
end
