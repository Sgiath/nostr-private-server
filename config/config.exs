import Config

# Configures the endpoint
config :client, Client.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: Client.ErrorHTML, json: Client.ErrorJSON],
    layout: false
  ],
  pubsub_server: Nostr.PubSub,
  live_view: [signing_salt: "MM25jTAs"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.16.10",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/client/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/client/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :client,
  relays: [
    "wss://nostr-pub.wellorder.net",
    "wss://nostr-verified.wellorder.net",
    "wss://nostr-relay.wlvs.space",
    "wss://nostr.openchain.fr",
    "wss://relay.damus.io",
    "wss://relay.nostr.info",
    # "wss://relay.minds.com/nostr/v1/ws",
    "wss://nostr.oxtr.dev",
    "wss://nostr.bitcoiner.social",
    "wss://nostr.onsats.org",
    "wss://nostr-pub.semisol.dev",
    "wss://nostr.ono.re",
    "wss://nostr-relay.untethr.me",
    "wss://nostr.noones.com",
    # "wss://nostr.fmt.wiz.biz",
    "wss://nostr.v0l.io",
    # "wss://brb.io",
    "wss://relay.nostr.bg"
  ]

import_config "#{config_env()}.exs"
