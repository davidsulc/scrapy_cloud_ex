defmodule ScrapyCloudEx.Endpoints.Helpers do
  @moduledoc false

  require Logger

  alias ScrapyCloudEx.HttpAdapter.{RequestConfig, Response}
  alias ScrapyCloudEx.HttpAdapters.Default, as: DefaultAdapter

  @typep param :: {atom, any}

  # parameter naming in the API is a bit inconsistent where multi-words variables are concerned
  # (e.g. include_headers vs lineend) and often doesn't conform to the Elixir convention of
  # snake_casing variables composed of multiple words, so this will allow us to accept both (e.g.)
  # `line_end` and `lineend` and convert them to the name the API expects
  @spec canonicalize_params(Keyword.t(), Keyword.t()) :: Keyword.t()
  def canonicalize_params(params, aliases) do
    params |> Enum.map(&canonicalize_param(&1, aliases))
  end

  @spec validate_params(Keyword.t(), [atom, ...]) :: :ok | ScrapyCloudEx.invalid_param_error()
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

  @spec invalid_param_error(String.t() | ScrapyCloudEx.tagged_error_info(), atom) ::
          ScrapyCloudEx.invalid_param_error()
  def invalid_param_error(error, tag) when is_atom(tag) or is_list(tag),
    do: {:invalid_param, {tag, error}}

  def make_request(%RequestConfig{} = config) do
    config = RequestConfig.ensure_defaults(config)
    %RequestConfig{opts: opts} = config
    Logger.debug("making request: #{inspect(config, pretty: true)}")
    http_client = get_http_client(opts)

    case http_client.request(config) do
      {:error, _} = error ->
        error

      {:ok, response} ->
        response = process_response(response)
        Logger.debug("received response: #{inspect(response, pretty: true)}")
        http_client.handle_response(response, opts)
    end
  end

  @spec canonicalize_param(param, Keyword.t()) :: param
  defp canonicalize_param({k, v} = pair, param_aliases) do
    case Keyword.get(param_aliases, k) do
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

  @spec get_http_client(Keyword.t()) :: atom
  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end

  @spec process_response(Response.t()) :: Response.t()
  defp process_response(%Response{} = response), do: maybe_unzip_body(response)

  @spec maybe_unzip_body(Response.t()) :: Response.t()
  defp maybe_unzip_body(%Response{body: body} = response) do
    body =
      if Response.gzipped?(response) do
        Logger.debug("gunzipping compressed body")
        :zlib.gunzip(body)
      else
        body
      end

    %{response | body: body}
  end
end
