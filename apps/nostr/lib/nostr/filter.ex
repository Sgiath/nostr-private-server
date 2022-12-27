defmodule Nostr.Filter do
  def parse(filter) when is_map(filter) do
    Map.take(filter, [:ids, :authors, :kinds, :"#e", :"#p", :since, :until, :limit])
  end
end
