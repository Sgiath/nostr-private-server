defmodule Nostr.Client do
  @moduledoc """
  Nostr client implementation
  """
  use Supervisor

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Supervisor
  def init(opts) do
    children = [
      {Registry, keys: :unique, name: Nostr.Client.RelayRegistry},
      Nostr.Client.Connections,
      {Registry, keys: :unique, name: Nostr.Client.SubscriptionRegistry},
      Nostr.Client.Subscriptions
    ]

    Task.start(fn ->
      # wait for supervisors to start
      :timer.sleep(10)
      for url <- Keyword.get(opts, :initial_relays, []), do: add_relay(url)
    end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defdelegate add_relay(url),
    to: Nostr.Client.Connections,
    as: :start_child

  defdelegate add_relay(url, read_only),
    to: Nostr.Client.Connections,
    as: :start_child

  defdelegate add_relay(url, read_only, notice_handler),
    to: Nostr.Client.Connections,
    as: :start_child

  defdelegate disconnect_relay(url), to: Nostr.Client.Connections, as: :terminate_child
  defdelegate get_cons, to: Nostr.Client.Connections, as: :children
  defdelegate set_notice_handler(handler), to: Nostr.Client.Connections

  defdelegate start_sub(id, filters), to: Nostr.Client.Subscriptions, as: :start_child
  defdelegate start_sub(id, filters, relays), to: Nostr.Client.Subscriptions, as: :start_child
  defdelegate subscribe_sub(id, s_pid), to: Nostr.Client.Subscriptions, as: :subscribe
  defdelegate close_sub(id), to: Nostr.Client.Subscriptions, as: :terminate_child
  defdelegate get_subs, to: Nostr.Client.Subscriptions, as: :children
  defdelegate get_events(id), to: Nostr.Client.Subscriptions, as: :events
end
