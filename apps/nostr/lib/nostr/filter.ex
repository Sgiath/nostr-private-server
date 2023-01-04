defmodule Nostr.Filter do
  @moduledoc """
  Nostr filter
  """

  defstruct [:ids, :authors, :kinds, :"#e", :"#p", :since, :until, :limit]

  @type t() :: %__MODULE__{
          ids: [<<_::32, _::_*8>>],
          authors: [<<_::32, _::_*8>>],
          kinds: [non_neg_integer()],
          "#e": [<<_::32, _::_*8>>],
          "#p": [<<_::32, _::_*8>>],
          since: non_neg_integer(),
          until: non_neg_integer(),
          limit: non_neg_integer()
        }

  def parse(filter) when is_map(filter) do
    filter
    |> Map.take([:ids, :authors, :kinds, :"#e", :"#p", :since, :until, :limit])
    |> Map.update(:since, nil, &DateTime.from_unix!/1)
    |> Map.update(:until, nil, &DateTime.from_unix!/1)
    |> Enum.into(%__MODULE__{})
  end
end

defimpl Jason.Encoder, for: Nostr.Filter do
  def encode(%Nostr.Filter{} = filter, opts) do
    filter
    |> Map.update!(:since, &encode_unix/1)
    |> Map.update!(:until, &encode_unix/1)
    |> Map.from_struct()
    |> Enum.reject(fn {_key, val} -> is_nil(val) end)
    |> Enum.into(%{})
    |> Jason.Encode.map(opts)
  end

  defp encode_unix(nil), do: nil
  defp encode_unix(date_time), do: DateTime.to_unix(date_time)
end
