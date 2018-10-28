defmodule ScrapyCloudEx.HttpAdapter.RequestConfig do
  @moduledoc false

  @type t :: %__MODULE__{}

  @http_methods [:get, :post, :put, :delete]
  @default_decoder ScrapyCloudEx.Decoders.Default

  defstruct [
    :api_key,
    :url,
    method: :get,
    headers: [],
    body: [],
    opts: [
      decoder: @default_decoder
    ]
  ]

  @spec new() :: t
  def new(), do: %__MODULE__{}

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

  def put(%__MODULE__{} = config, key, value) when key in [:headers, :body, :opts] do
    if tuple_list?(value) do
      config |> Map.put(key, value)
    else
      raise ArgumentError,
        message: "value for key '#{key}' must be a list of tuples (such as a keyword list)"
    end
  end

  def put(%__MODULE__{}, _, _) do
    valid_keys = new() |> Map.keys()
    raise ArgumentError, message: "key must be one of #{inspect(valid_keys)}"
  end

  @spec ensure_defaults(t()) :: t()
  def ensure_defaults(%__MODULE__{} = config) do
    config
    |> ensure_decoder()
    |> default_encoding_to_gzip()
  end

  @spec tuple_list?(any) :: boolean
  defp tuple_list?([]), do: true
  defp tuple_list?([{_, _} | t]), do: tuple_list?(t)
  defp tuple_list?(_), do: false

  @spec ensure_decoder(t()) :: t()
  defp ensure_decoder(config) do
    if Keyword.get(config.opts, :decoder) do
      config
    else
      %{config | opts: Keyword.put(config.opts, :decoder, @default_decoder)}
    end
  end

  @spec default_encoding_to_gzip(t()) :: t()
  defp default_encoding_to_gzip(config) do
    if has_encoding_header?(config.headers) do
      config
    else
      %{config | headers: [{:"Accept-Encoding", "gzip"} | config.headers]}
    end
  end

  @spec has_encoding_header?([{String.t(), String.t()}]) :: boolean()

  defp has_encoding_header?([]), do: false

  defp has_encoding_header?([{k, _} | t]) do
    if k |> Atom.to_string() |> String.downcase() == "accept-encoding" do
      true
    else
      has_encoding_header?(t)
    end
  end
end
