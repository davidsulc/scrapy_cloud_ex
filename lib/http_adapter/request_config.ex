defmodule ScrapyCloudEx.HttpAdapter.RequestConfig do
  @moduledoc """
  Struct containing the configuration for an API call.
  """

  @typedoc """
  Contains the configuration relevant for an API request:

  * `:api_key` - the API key as can be obtained [here](https://app.scrapinghub.com/account/apikey).
      This must be provided to the API either by using HTTP Basic authentication (which is the approach
      used by `ScrapyCloudEx.HttpAdapters.Default`), or within the URL as a query parameter:
      `https://storage.scrapinghub.com/foo?apikey=APIKEY`.
      See [docs](https://doc.scrapinghub.com/scrapy-cloud.html#authentication) for more info.

  * `:url` - the API URL to send the request to. May contain query parameters.

  * `:method` - HTTP request method to use. Supported values are: `:get`, `:post`, `:put`, `:delete`.

  * `:headers` - headers to add to the request. By default a `{:"Accept-Encoding", "gzip"}` is always present.

  * `:body` - request body.

  * `:opts` - any options provided to an endpoint method will be provided here. Always contains a `:decoder`
      value which is either a module implementing the `ScrapyCloudEx.Decoder` behaviour, or a function
      satisfying the `t:ScrapyCloudEx.Decoder.decoder_function/0` type. Adding values here can be particularly
      useful to work around certain API quirks, such as the `ScrapyCloudEx.Endpoints.App.Jobs.list/4` endpoint
      which will return a "text/plain" encoding value when requesting the `:jl` format. By adding (for example)
      the requested format in the `:opts` parameter of the endpoint call, the implementation of
      `c:ScrapyCloudEx.HttpAdapter.handle_response/2` can process the body as appropriate.
  """
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

  @doc false
  @spec new() :: t
  def new(), do: %__MODULE__{}

  @doc false
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

  @doc false
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
