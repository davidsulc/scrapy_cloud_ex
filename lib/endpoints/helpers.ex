defmodule ScrapingHubEx.Endpoints.Helpers do
  @moduledoc false

  require Logger

  alias ScrapingHubEx.HttpAdapter.RequestConfig
  alias ScrapingHubEx.HttpAdapters.Default, as: DefaultAdapter

  def validate_params(params, expected) do
    params
    |> Enum.reject(&param_valid?(expected, &1))
    |> case do
      [] ->
        :ok

      invalid_params ->
        "valid params: #{inspect(expected |> Enum.sort())}"
        |> invalid_param_error(Keyword.keys(invalid_params))
    end
  end

  def invalid_param_error(error, tag) when is_atom(tag) or is_list(tag),
    do: {:invalid_param, {tag, error}}

  def make_request(%RequestConfig{opts: opts} = config) do
    Logger.debug("making request: #{inspect(config)}")
    http_client = get_http_client(opts)
    config |> http_client.request()
  end

  defp param_valid?(valid, {k, _}), do: valid |> param_valid?(k)
  defp param_valid?(valid, param), do: valid |> Enum.member?(param)

  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end
end
