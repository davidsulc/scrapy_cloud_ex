defmodule ScrapyCloudEx.Endpoints.Storage.Requests do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.Endpoints.Storage.QueryParams
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @typedoc """
  A request object.

  Map with the following keys:

  * `"time"` - request start timestamp in milliseconds (`t:integer/0`).
  * `"method"` - HTTP method. Defaults to `"GET"` (`t:String.t/0`).
  * `"url"` - request URL (`t:String.t/0`).
  * `"status"` - HTTP response code (`t:integer/0`).
  * `"duration"` - request duration in milliseconds (`t:integer/0`).
  * `"rs"` - response size in bytes (`t:integer/0`).
  * `"parent"` - index of the parent request (`t:integer/0`).
  * `"fp"` - request fingerprint (`t:String.t/0`).
  """
  @type request_object :: %{ required(String.t()) => integer() | String.t() }

  @base_url "https://storage.scrapinghub.com/requests"

  @spec get(String.t(), String.t(), Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result([request_object()])
  def get(api_key, composite_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(params)
      when is_list(opts) do
    with %QueryParams{error: nil} = query_params <- params |> QueryParams.from_keywords() do
      query_string =
        query_params
        |> warn_if_no_pagination(composite_id)
        |> QueryParams.to_query()

      base_url = [@base_url, composite_id] |> Enum.join("/")

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:url, "#{base_url}?#{query_string}")
      |> RequestConfig.put(:headers, Keyword.get(opts, :headers, []))
      |> RequestConfig.put(:opts, opts)
      |> Helpers.make_request()
    else
      %QueryParams{error: error} -> {:error, error}
      error -> {:error, error}
    end
  end

  # returns e.g.
  # %{
  #  "counts" => %{
  #    "duration" => 2888,
  #    "fp" => 2888,
  #    "method" => 2888,
  #    "parent" => 2886,
  #    "rs" => 2888,
  #    "status" => 2888,
  #    "url" => 2888
  #  },
  #  "totals" => %{"input_bytes" => 374000, "input_values" => 2888}
  # }
  @spec stats(String.t(), String.t(), Keyword.t()) :: ScrapyCloudEx.result(map())
  def stats(api_key, composite_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id)
      when is_list(opts) do
    with 3 <- composite_id |> String.split("/") |> length() do
      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:opts, opts)
      |> RequestConfig.put(:url, [@base_url, composite_id, "stats"] |> Enum.join("/"))
      |> Helpers.make_request()
    else
      _ ->
        error =
          "expected `id` param to have exactly 3 sections"
          |> Helpers.invalid_param_error(:id)

        {:error, error}
    end
  end

  @spec warn_if_no_pagination(QueryParams.t(), String.t()) :: QueryParams.t()
  defp warn_if_no_pagination(%QueryParams{} = query_params, id) when is_binary(id) do
    case id |> String.split("/") |> length() do
      count when count < 4 -> warn_if_no_pagination(query_params)
      _count -> :ok
    end

    query_params
  end

  @spec warn_if_no_pagination(QueryParams.t()) :: QueryParams.t()
  defp warn_if_no_pagination(%QueryParams{} = query_params) do
    query_params |> QueryParams.warn_if_no_pagination("#{__MODULE__}.get/4")
  end
end
