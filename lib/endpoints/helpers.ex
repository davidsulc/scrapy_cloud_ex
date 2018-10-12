defmodule ScrapyCloudEx.Endpoints.Helpers do
  @moduledoc false

  require Logger

  alias ScrapyCloudEx.HttpAdapter.RequestConfig
  alias ScrapyCloudEx.HttpAdapters.Default, as: DefaultAdapter

  # parameter naming in the API is a bit inconsistent where multi-words variables are concerned
  # (e.g. include_headers vs lineend) and often doesn't conform to the Elixir convention of
  # snake_casing variables composed of multiple words, so this will allow us to accept both (e.g.)
  # `line_end` and `lineend` and convert them to the name the API expects
  def canonicalize_params(params, synonyms) do
    params |> Enum.map(&canonicalize_param(&1, synonyms))
  end

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

  def invalid_param_error(error, tag) when is_atom(tag) or is_list(tag),
    do: {:invalid_param, {tag, error}}

  def set_default_decoder_format(opts, nil), do: opts

  def set_default_decoder_format(opts, decoder_format)
      when is_list(opts) and is_atom(decoder_format) do
    case Keyword.get(opts, :decoder_format) do
      nil -> Keyword.put(opts, :decoder_format, decoder_format)
      _ -> opts
    end
  end

  def make_request(%RequestConfig{opts: opts} = config) do
    Logger.debug("making request: #{inspect(config)}")
    http_client = get_http_client(opts)

    case http_client.request(config) do
      {:error, _} = error ->
        error

      {:ok, response} ->
        Logger.debug("received response: #{inspect(response)}")
        http_client.handle_response(response, opts)
    end
  end

  defp canonicalize_param({k, v} = pair, param_synonyms) do
    case Keyword.get(param_synonyms, k) do
      nil ->
        pair

      canonical_name ->
        Logger.warn("replacing '#{inspect(k)}' parameter with '#{inspect(canonical_name)}'")
        {canonical_name, v}
    end
  end

  defp param_valid?(valid, {k, _}), do: valid |> param_valid?(k)
  defp param_valid?(valid, param), do: valid |> Enum.member?(param)

  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end
end
