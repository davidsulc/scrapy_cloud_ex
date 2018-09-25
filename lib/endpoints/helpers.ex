defmodule SHEx.Endpoints.Helpers do
  @moduledoc false

  alias SHEx.HttpAdapter.RequestConfig
  alias SHEx.HttpAdapters.Default, as: DefaultAdapter

  def validate_params(params, expected) do
    params
    |> Enum.reject(fn {k, _} -> Enum.member?(expected, k) end)
    |> case do
      [] ->
        :ok

      invalid_params ->
        {:invalid_param, {Keyword.keys(invalid_params), "valid params: #{inspect(expected)}"}}
    end
  end

  def make_request(%RequestConfig{opts: opts} = config) do
    http_client = get_http_client(opts)
    config |> http_client.request()
  end

  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end
end
