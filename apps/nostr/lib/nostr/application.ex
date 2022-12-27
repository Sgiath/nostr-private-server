defmodule Nostr.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Nostr.Repo,
      {Phoenix.PubSub, name: Nostr.PubSub},
      {Finch, name: Nostr.Finch},
      Nostr
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Nostr.Supervisor)
  end
end
