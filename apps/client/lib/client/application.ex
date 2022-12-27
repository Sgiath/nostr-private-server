defmodule Client.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      Client.Telemetry,
      # Start the Endpoint (http/https)
      Client.Endpoint
      # Start a worker by calling: Client.Worker.start_link(arg)
      # {Client.Worker, arg}
      # {Client.Connection, "wss://relay.damus.io"}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Client.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Client.Endpoint.config_change(changed, removed)
    :ok
  end
end
