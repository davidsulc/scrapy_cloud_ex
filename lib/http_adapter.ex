defmodule ScrapyCloudEx.HttpAdapter do
  @moduledoc """
  Defines the behaviour used to process the body of API responses.

  A module implementing this behaviour can be used for making http calls to
  API endpoints by using the `:http_adapter` key in the
  [`opts`](ScrapyCloudEx.Endpoints.html#module-options) parameter of every
  endpoint module.
  """

  alias ScrapyCloudEx.HttpAdapter.{RequestConfig, Response}

  @type error_map :: %{status: integer, message: any}

  @doc """
  Invoked to make a request to an API endpoint.

  The `opts` attribute of the `ScrapyCloudEx.HttpAdapter.RequestConfig`
  parameter will always have a `:decoder` value provided, which defaults to
  `ScrapyCloudEx.Decoders.Default`.

  By default, the `headers` attribute will contain a `{:"Accept-Encoding", "gzip"}`
  value. This header should be sent to the API endpoint if a compressed repsonse
  is desired. Not all API endpoints support compressed responses, but providing
  this header to endpoints that don't support it won't result in an error. If a
  compressed response is received, it will be handled and decompressed transparently.
  """
  @callback request(request :: RequestConfig.t()) ::
              {:ok, Response.t()} | ScrapyCloudEx.tagged_error()

  @doc """
  Invoked to process a response from the API.

  The `body` attribute of the `response` will always be decompressed, even if
  the API responded with a gzipped reply.
  """
  @callback handle_response(response :: Response.t(), opts :: Keyword.t()) ::
              {:ok, any} | {:error, error_map}
end
