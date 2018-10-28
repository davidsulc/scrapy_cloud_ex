defmodule ScrapyCloudEx.HttpAdapter do
  @moduledoc """
  Defines the behaviour used to process the body of API responses.
  """

  alias ScrapyCloudEx.HttpAdapter.{RequestConfig, Response}

  @type error_map :: %{status: integer, message: any}

  @callback request(%RequestConfig{}) :: {:ok, Response.t} | ScrapyCloudEx.tagged_error
  @callback handle_response(%Response{}, list) :: {:ok, any} | {:error, error_map}
end
