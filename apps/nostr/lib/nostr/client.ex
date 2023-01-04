defmodule Nostr.Client do
  @moduledoc """
  Nostr client implementation
  """
  use GenServer

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Public API

  @doc """
  Create connection to new relay
  """
  @spec add_relay(url :: String.t(), read_only :: boolean()) :: :ok
  def add_relay(url, read_only \\ false) do
    GenServer.cast(__MODULE__, {:add_relay, url, read_only})
  end

  def disconnect_relay(url) do
    GenServer.cast(__MODULE__, {:disconnect_relay, url})
  end

  @doc """
  Start new subscription
  """
  @spec start_sub(id :: String.t(), filters :: [Nostr.Filter.t()], relays :: :all | [String.t()]) ::
          :ok
  def start_sub(id, filters, relays \\ :all) do
    GenServer.cast(__MODULE__, {:start_sub, id, filters, relays, [self()]})
  end

  @doc """
  Close subscription
  """
  @spec close_sub(id :: String.t()) :: :ok
  def close_sub(id) do
    GenServer.cast(__MODULE__, {:close_sub, id})
  end

  @doc """
  Get active subscriptions
  """
  @spec get_subs() :: []
  def get_subs do
    GenServer.call(__MODULE__, :get_subscriptions)
  end

  def get_cons do
    GenServer.call(__MODULE__, :get_connections)
  end

  # Internals

  @impl GenServer
  def init(opts) do
    initial_relays = Keyword.get(opts, :initial_relays, [])

    state = %{
      connections: %{},
      subscriptions: %{}
    }

    {:ok, state, {:continue, initial_relays}}
  end

  @impl GenServer
  def handle_continue(initial_relays, state) do
    DynamicSupervisor.start_link(name: Nostr.Client.Connections)
    DynamicSupervisor.start_link(name: Nostr.Client.Subscriptions)

    connections =
      initial_relays
      |> Enum.map(fn url ->
        {:ok, pid} =
          DynamicSupervisor.start_child(
            Nostr.Client.Connections,
            {Nostr.Connection, [url: url, read_only: false]}
          )

        {url, %{pid: pid}}
      end)
      |> Enum.into(%{})

    {:noreply, Map.put(state, :connections, connections)}
  end

  @impl GenServer
  def handle_call(:get_subscriptions, _from, state) do
    {:reply, state.subscriptions, state}
  end

  def handle_call(:get_connections, _from, state) do
    {:reply, state.connections, state}
  end

  @impl GenServer
  def handle_cast({:add_relay, url, read_only}, state) do
    if Map.has_key?(state.connections, url) do
      Logger.warning("Relay #{url} already connected")
      {:noreply, state}
    else
      {:ok, pid} =
        DynamicSupervisor.start_child(
          Nostr.Client.Connections,
          {Nostr.Connection, [url: url, read_only: read_only]}
        )

      {:noreply, Map.update!(state, :connections, &Map.put(&1, url, %{pid: pid}))}
    end
  end

  def handle_cast({:disconnect_relay, url}, state) do
    pid =
      state.connections
      |> Map.get(url)
      |> Map.get(:pid)

    DynamicSupervisor.terminate_child(Nostr.Client.Connections, pid)

    {:noreply, Map.update!(state, :connections, &Map.delete(&1, url))}
  end

  def handle_cast({:start_sub, id, filters, :all, subs}, state) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        Nostr.Client.Subscriptions,
        {Nostr.Subscription, [id: id, filters: filters, relays: state.connections, subscribers: subs]}
      )

    {:noreply, Map.update!(state, :subscriptions, &Map.put(&1, id, %{pid: pid}))}
  end

  def handle_cast({:start_sub, id, filters, relays, subs}, state) do
    relays = Map.filter(state.connections, fn {url, _val} -> url in relays end)

    {:ok, pid} =
      DynamicSupervisor.start_child(
        Nostr.Client.Subscriptions,
        {Nostr.Subscription, [id: id, filters: filters, relays: relays, subscribers: subs]}
      )

    {:noreply, Map.update!(state, :subscriptions, &Map.put(&1, id, %{pid: pid}))}
  end

  def handle_cast({:close_sub, id}, state) do
    pid =
      state.subscriptions
      |> Map.get(id)
      |> Map.get(:pid)

    GenServer.call(pid, :close)
    DynamicSupervisor.terminate_child(Nostr.Client.Subscriptions, pid)

    {:noreply, Map.update!(state, :subscriptions, &Map.delete(&1, id))}
  end

  def handle_cast({:publish_event, event}, state) do
    event
    |> Nostr.Message.create_event()
    |> Nostr.Message.serialize()
    |> send_msg()

    {:noreply, state}
  end

  defp send_msg(msg) do
    for {:undefined, pid, :worker, [Nostr.Connection]} <-
          DynamicSupervisor.which_children(Nostr.Client.Connections) do
      GenServer.cast(pid, {:send, msg})
    end
  end
end
