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
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Client.Supervisor)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Client.Endpoint.config_change(changed, removed)
    :ok
  end
end
