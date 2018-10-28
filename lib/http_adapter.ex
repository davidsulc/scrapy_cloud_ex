defmodule ScrapyCloudEx.HttpAdapter do
  @moduledoc """
  Defines the behaviour used to process the body of API responses.
  """

  alias ScrapyCloudEx.HttpAdapter.{RequestConfig, Response}

  @type error_map :: %{status: integer, message: any}

  @callback request(request :: RequestConfig.t()) ::
              {:ok, Response.t()} | ScrapyCloudEx.tagged_error()
  @callback handle_response(response :: Response.t(), opts :: Keyword.t()) ::
              {:ok, any} | {:error, error_map}
end
