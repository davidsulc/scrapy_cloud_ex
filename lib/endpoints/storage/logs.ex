defmodule ScrapyCloudEx.Endpoints.Storage.Logs do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.Endpoints.Storage.QueryParams
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/logs"

  def get(api_key, composite_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(params)
      when is_list(opts) do
    with %QueryParams{error: nil} = query_params <- params |> QueryParams.from_keywords() do
      query_string = query_params |> QueryParams.to_query()
      base_url = [@base_url, composite_id] |> Enum.join("/")

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:url, "#{base_url}?#{query_string}")
      |> RequestConfig.put(:headers, Keyword.get(opts, :headers, []))
      |> RequestConfig.merge_opts(decoder_format: Keyword.get(params, :format, :json))
      |> RequestConfig.merge_opts(opts)
      |> Helpers.make_request()
    else
      %QueryParams{error: error} -> {:error, error}
      error -> {:error, error}
    end
  end
end
