defmodule ScrapyCloudEx.HttpAdapter do
  alias ScrapyCloudEx.HttpAdapter.{RequestConfig, Response}

  @callback request(%RequestConfig{}) :: {:ok, %Response{}} | {:error, any}
  @callback handle_response(%Response{}, list) :: {:ok, any} | {:error, map}
end
