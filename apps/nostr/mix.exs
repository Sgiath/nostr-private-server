defmodule Nostr.MixProject do
  use Mix.Project

  def project do
    [
      # App config
      app: :nostr,
      version: "0.1.0",

      # Elixir config
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Umbrella paths
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},

      # Cryptography
      {:secp256k1, git: "https://git.sr.ht/~sgiath/secp256k1"},

      # HTTP client
      {:gun, "~> 2.0.0-rc.2"}
      # {:certifi, "~> 2.10"},
      # {:ssl_verify_fun, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
