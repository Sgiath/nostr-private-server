defmodule Nostr.Repo do
  use Ecto.Repo,
    otp_app: :nostr,
    adapter: Ecto.Adapters.Postgres
end
