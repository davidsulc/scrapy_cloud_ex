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
        "valid params: #{inspect(expected |> Enum.sort())}"
        |> invalid_param_error(Keyword.keys(invalid_params))
    end
  end

  def invalid_param_error(error, tag) when is_atom(tag) or is_list(tag), do: {:invalid_param, {tag, error}}

  def make_request(%RequestConfig{opts: opts} = config) do
    http_client = get_http_client(opts)
    config |> http_client.request()
  end

  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end
end
