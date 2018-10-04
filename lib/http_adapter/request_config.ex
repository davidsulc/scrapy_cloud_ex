defmodule ScrapyCloudEx.HttpAdapter.RequestConfig do
  defstruct [
    :api_key,
    :url,
    method: :get,
    headers: [],
    body: [],
    opts: []
  ]

  def new(), do: %__MODULE__{}
end
