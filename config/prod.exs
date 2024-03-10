import Config

config :client, Client.Endpoint,
  url: [host: "nostr.sgiath.dev", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info
