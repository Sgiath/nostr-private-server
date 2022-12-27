defmodule Nostr do
  use DynamicSupervisor

  def test do
    Nostr.start_child("wss://relay.damus.io")

    for {:undefined, pid, :worker, [_name]} <- DynamicSupervisor.which_children(Nostr) do
      WebSockex.cast(
        pid,
        {:req, :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower),
         %{
           authors: ["0000002855ad7906a7568bf4d971d82056994aa67af3cf0048a825415ac90672"],
           since: 0
         }}
      )
    end
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(url, read_only \\ false) do
    DynamicSupervisor.start_child(__MODULE__, {Nostr.Connection, url: url, read_only: read_only})
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
