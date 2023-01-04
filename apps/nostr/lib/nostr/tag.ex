defmodule Nostr.Tag do
  @moduledoc """
  Nostr Event tag
  """

  @enforce_keys [:type, :data]
  defstruct type: nil, data: nil, info: []

  @type t() :: %__MODULE__{
          type: atom(),
          data: binary(),
          info: [String.t()]
        }

  def parse([type, data | info]) do
    %__MODULE__{
      type: String.to_atom(type),
      data: data,
      info: info
    }
  end
end

defimpl Jason.Encoder, for: Nostr.Tag do
  def encode(%Nostr.Tag{} = tag, opts) do
    Jason.Encode.list([Atom.to_string(tag.type), tag.data | tag.info], opts)
  end
end
