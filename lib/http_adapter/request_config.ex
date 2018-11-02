defmodule ScrapyCloudEx.HttpAdapter.RequestConfig do
  @type t :: %__MODULE__{}

  @http_methods [:get, :post, :put, :delete]

  defstruct [
    :api_key,
    :url,
    method: :get,
    headers: [],
    body: [],
    opts: [
      decoder: ScrapyCloudEx.Decoders.Default
    ]
  ]

  @spec new() :: t
  def new(), do: %__MODULE__{}

  @spec merge_opts(t, Keyword.t) :: t
  def merge_opts(%__MODULE__{opts: opts} = struct, new_opts) when is_list(new_opts) do
    %{struct | opts: Keyword.merge(opts, new_opts)}
  end

  @spec put(t, atom | any, any) :: t

  def put(%__MODULE__{} = config, key, value) when key in [:api_key, :url] and is_binary(value) do
    config |> Map.put(key, value)
  end

  def put(%__MODULE__{}, key, _) when key in [:api_key, :url] do
    raise ArgumentError, message: "value for key '#{key}' must be a string"
  end

  def put(%__MODULE__{} = config, :method, method) when method in @http_methods do
    config |> Map.put(:method, method)
  end

  def put(%__MODULE__{}, :method, _) do
    raise ArgumentError, message: "method must be one of #{inspect(@http_methods)}"
  end

  def put(%__MODULE__{} = config, key, value) when key in [:headers, :body] do
    if tuple_list?(value) do
      config |> Map.put(key, value)
    else
      raise ArgumentError,
        message: "value for key '#{key}' must be a list of tuples (such as a keyword list)"
    end
  end

  # so that default opts don't inadvertently get removed without a replacement value
  def put(%__MODULE__{}, :opts, _value) do
    raise ArgumentError, message: "use #{__MODULE__}.merge_opts/2 to add options"
  end

  def put(%__MODULE__{}, _, _) do
    valid_keys = new() |> Map.keys()
    raise ArgumentError, message: "key must be one of #{inspect(valid_keys)}"
  end

  @spec tuple_list?(any) :: boolean
  defp tuple_list?([]), do: true
  defp tuple_list?([{_, _} | t]), do: tuple_list?(t)
  defp tuple_list?(_), do: false
end
