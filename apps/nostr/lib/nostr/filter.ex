defmodule Nostr.Filter do
  @moduledoc """
  Nostr filter
  """

  defstruct [:ids, :authors, :kinds, :"#e", :"#p", :since, :until, :limit]

  def parse(filter) when is_map(filter) do
    Map.take(filter, [:ids, :authors, :kinds, :"#e", :"#p", :since, :until, :limit])
  end
end

defimpl Jason.Encoder, for: Nostr.Filter do
  def encode(%Nostr.Filter{} = filter, opts) do
    filter
    |> Map.from_struct()
    |> Enum.reject(fn {_key, val} -> is_nil(val) end)
    |> Enum.into(%{})
    |> Jason.Encode.map(opts)
  end
end
