defmodule ScrapyCloudEx.Endpoints do
  @moduledoc """
  Documents commonalities between all endpoint-related functions.

  ## Options
  
  The last argument provided to most endpoint functions is a keyword list
  of options. These options are made available to the HttpAdapter during the
  API request.

  - `decoder`: specifies how the response body should be processed. Can be
    a module implementing the `ScrapyCloudEx.Decoder` behaviour, or a function
    returning `{:ok, term()} | {:error, term()}` where `:ok` and `:error`
    indicate whether decoding the body was successfull. Defaults to
    `ScrapyCloudEx.Decoders.Default`.

  - `headers`: list of headers that are added to the `ScrapyCloudEx.HttpAdapter.RequestConfig`
    `headers` attribute provided to the HttpAdapter instance making the API call.
    The default HttpAdapter does not make use of this option.

  - `http_adapter`: specifies the module to use to make the HTTP request to
    the API. This module is expected to implement the `ScrapyCloudEx.HttpAdapter`
    behaviour. Defaults to `ScrapyCloudEx.HttpAdapters.Default`.
  """
end
