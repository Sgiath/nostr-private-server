defmodule Client.Config do
  @moduledoc """
  Configuration
  """

  def seckey do
    Application.get_env(:client, :seckey)
  end

  def pubkey do
    seckey()
    |> Base.decode16!(case: :lower)
    |> Secp256k1.pubkey(:xonly)
    |> Base.encode16(case: :lower)
  end

  def relays do
    Application.get_env(:client, :relays, [])
  end
end
