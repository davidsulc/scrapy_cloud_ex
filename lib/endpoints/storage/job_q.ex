defmodule ScrapyCloudEx.Endpoints.Storage.JobQ do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/jobq"

  @default_format :json

  @param_synonyms [
    {:start_ts, :startts},
    {:end_ts, :endts}
  ]

  @valid_params [:spider, :state, :startts, :endts, :has_tag, :lacks_tag, :format]

  def count(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
    make_request(api_key, project_id, params, opts, @valid_params, "count")
  end

  def list(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
    valid_params = @valid_params ++ [:start, :stop, :key]
    make_request(api_key, project_id, params, opts, valid_params, "list")
  end

  defp make_request(api_key, project_id, params, opts, valid_params, endpoint) do
    params =
      params
      |> set_default_format()
      |> Helpers.canonicalize_params(@param_synonyms)

    with :ok <- Helpers.validate_params(params, valid_params) do
      base_url = [@base_url, project_id, endpoint] |> Enum.join("/")
      query_string = URI.encode_query(params)

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:url, "#{base_url}?#{query_string}")
      |> RequestConfig.put(:headers, Keyword.get(opts, :headers, []))
      |> RequestConfig.merge_opts(opts)
      |> Helpers.make_request()
    else
      error -> {:error, error}
    end
  end

  defp set_default_format(params) do
    case Keyword.get(params, :format) do
      nil -> Keyword.put(params, :format, @default_format)
      _ -> params
    end
  end
end
