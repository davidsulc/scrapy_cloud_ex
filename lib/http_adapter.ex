defmodule SHEx.HttpAdapter do
  defmodule RequestData do
    defstruct headers: [], body: []
  end

  @type error :: :request_error | :api_error | :json_error
  @type request_type :: :get | :post

  @callback request(type :: request_type, api_key :: String.t, url :: String.t, data :: %RequestData{}, opts :: keyword) ::
    {:ok, map} | {:error, {error, any}}
end
