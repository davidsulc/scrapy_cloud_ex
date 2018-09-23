defmodule SHEx.HttpAdapter do
  alias SHEx.HttpAdapter.RequestConfig

  @type error :: :request_error | :api_error | :json_error

  @callback request(%RequestConfig{}) :: {:ok, map} | {:error, {error, any}}
end
