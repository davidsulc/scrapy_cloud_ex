defmodule ScrapyCloudEx.HttpAdapter.RequestConfig do
  defstruct [
    :api_key,
    :url,
    method: :get,
    headers: [],
    body: [],
    opts: [
      decoder: ScrapyCloudEx.Decoders.Default,
      decoder_format: :json
    ]
  ]

  def new(), do: %__MODULE__{}

  def merge_opts(%__MODULE__{opts: opts} = struct, new_opts) do
    %{struct | opts: Keyword.merge(opts, new_opts)}
  end

  # so that default opts don't inadvertently get removed without a replacement value
  def put(%__MODULE__{}, :opts, _value) do
    raise ArgumentError, message: "use #{__MODULE__}.merge_opts/2 to add options"
  end

  def put(%__MODULE__{} = struct, key, value), do: Map.put(struct, key, value)
end
