defmodule ScrapyCloudEx.HttpAdapter do
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @type error :: :request_error | :api_error | :decoder_error

  @callback request(%RequestConfig{}) :: {:ok, map} | {:error, {error, any}}
end
