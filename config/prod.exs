import Config

config :client, Client.Endpoint,
  url: [host: "nostr.sgiath.dev", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info
