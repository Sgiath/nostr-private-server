import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :client, Client.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: Client.ErrorHTML, json: Client.ErrorJSON],
    layout: false
  ],
  pubsub_server: Nostr.PubSub,
  live_view: [signing_salt: "MM25jTAs"]

config :esbuild,
  version: "0.17.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/client/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/client/assets", __DIR__)
  ]

config :phoenix, :json_library, Jason

config :client,
  relays: [
    "wss://nostr-pub.wellorder.net",
    "wss://nostr-verified.wellorder.net",
    "wss://eden.nostr.land",
    "wss://relay.damus.io",
    "wss://nostr.oxtr.dev",
    "wss://nostr.noones.com",
    "wss://relay.nostr.bg",
    "wss://relay.plebstr.com",
    "wss://nostr.wine",
    "wss://relay.ryzizub.com",
    "wss://nostr.zebedee.cloud",
    "wss://relay.current.fyi",
    "wss://relay.nostr.band",
    "wss://nos.lol",
    "wss://offchain.pub",
    "wss://relay.snort.social",
    "wss://nostr-relay.derekross.me",
    "wss://no-str.org",
    "wss://nostr.rocketnode.space",
    "wss://nostr.21crypto.ch",
    "wss://relay.nostr.express"
  ]

import_config "#{config_env()}.exs"
