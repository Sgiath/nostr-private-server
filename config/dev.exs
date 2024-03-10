import Config

config :logger, :console, format: "[$level] $message\n"

config :client, Client.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "m0l7v/sWSIgCy1gv0fXCOqDjA9bpZK2ZQaIJLMN9cJ0N4EcR7ek0y8Uaoyk868Ds",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/client/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :phoenix,
  plug_init_mode: :runtime,
  stacktrace_depth: 20

config :client, dev_routes: true
