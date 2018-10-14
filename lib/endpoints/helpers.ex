defmodule ScrapyCloudEx.Endpoints.Helpers do
  @moduledoc false

  require Logger

  alias ScrapyCloudEx.HttpAdapter.RequestConfig
  alias ScrapyCloudEx.HttpAdapters.Default, as: DefaultAdapter

  @typep param :: {atom, any}
  @typep invalid_param_error :: {:invalid_param, ScrapyCloudEx.tagged_error}

  # parameter naming in the API is a bit inconsistent where multi-words variables are concerned
  # (e.g. include_headers vs lineend) and often doesn't conform to the Elixir convention of
  # snake_casing variables composed of multiple words, so this will allow us to accept both (e.g.)
  # `line_end` and `lineend` and convert them to the name the API expects
  @spec canonicalize_params(Keyword.t, Keyword.t) :: Keyword.t
  def canonicalize_params(params, synonyms) do
    params |> Enum.map(&canonicalize_param(&1, synonyms))
  end

  @spec validate_params(Keyword.t, [atom, ...]) :: :ok | invalid_param_error
  def validate_params(params, expected) when is_list(params) and is_list(expected) do
    params
    |> Enum.reject(&param_valid?(expected, &1))
    |> case do
      [] ->
        :ok

      [{invalid_param, _} | _] ->
        "valid params: #{inspect(expected |> Enum.sort())}"
        |> invalid_param_error(invalid_param)
    end
  end

  @spec invalid_param_error(String.t | ScrapyCloudEx.tagged_error, atom) :: invalid_param_error
  def invalid_param_error(error, tag) when is_atom(tag) or is_list(tag),
    do: {:invalid_param, {tag, error}}

  def make_request(%RequestConfig{opts: opts} = config) do
    Logger.debug("making request: #{inspect(config, pretty: true)}")
    http_client = get_http_client(opts)

    case http_client.request(config) do
      {:error, _} = error ->
        error

      {:ok, response} ->
        Logger.debug("received response: #{inspect(response, pretty: true)}")
        http_client.handle_response(response, opts)
    end
  end

  @spec canonicalize_param(param, Keyword.t) :: param
  defp canonicalize_param({k, v} = pair, param_synonyms) do
    case Keyword.get(param_synonyms, k) do
      nil ->
        pair

      canonical_name ->
        Logger.warn("replacing '#{inspect(k)}' parameter with '#{inspect(canonical_name)}'")
        {canonical_name, v}
    end
  end

  @spec param_valid?([atom], {atom, any} | atom) :: boolean
  defp param_valid?(valid, {k, _}), do: valid |> param_valid?(k)
  defp param_valid?(valid, param), do: valid |> Enum.member?(param)

  @spec get_http_client(Keyword.t) :: atom
  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end
end
