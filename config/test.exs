import Config

config :client, Client.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "vl0ZIycZOyra3jEh1ki/pM6QAkbnMw4veRfv7LSWxa2r1ydqDZ05Np3+qj3iYBPq",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
