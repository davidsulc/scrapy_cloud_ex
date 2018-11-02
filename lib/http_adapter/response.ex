defmodule ScrapyCloudEx.HttpAdapter.Response do
  @moduledoc """
  Struct containing the response from an API call.
  """

  @typedoc """
  Contains the information returned by an API call:

  * `:status` - the HTTP status returned.

  * `:headers` - the HTTP headers returned.

  * `:body` - the (uncompressed) body returned: if the body was compressed with gzip, it will
      have been decompressed before being added to the struct.
  """
  @type t :: %__MODULE__{}

  defstruct [
    :status,
    headers: [],
    body: ""
  ]

  @doc false
  @spec gzipped?(t) :: boolean
  def gzipped?(%__MODULE__{headers: headers}) do
    Enum.find(headers, false, fn
      {"Content-Encoding", "gzip"} -> true
      _ -> false
    end)
  end
end
