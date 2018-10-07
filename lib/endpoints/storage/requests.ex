defmodule ScrapyCloudEx.Endpoints.Storage.Requests do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.Endpoints.Storage.QueryParams
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/requests"

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
      opts = opts |> Helpers.set_default_decoder_format(Keyword.get(params, :format))

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:url, "#{base_url}?#{query_string}")
      |> RequestConfig.put(:headers, Keyword.get(opts, :headers, []))
      |> RequestConfig.merge_opts(opts)
      |> Helpers.make_request()
    else
      %QueryParams{error: error} -> {:error, error}
      error -> {:error, error}
    end
  end

  def stats(api_key, composite_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id)
      when is_list(opts) do
    with 3 <- composite_id |> String.split("/") |> length() do
      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.merge_opts(opts)
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

  defp warn_if_no_pagination(%QueryParams{} = query_params, id) when is_binary(id) do
    case id |> String.split("/") |> length() do
      count when count < 4 -> warn_if_no_pagination(query_params)
      _count -> :ok
    end

    query_params
  end

  defp warn_if_no_pagination(%QueryParams{} = query_params) do
    query_params |> QueryParams.warn_if_no_pagination("#{__MODULE__}.get/4")
  end
end
