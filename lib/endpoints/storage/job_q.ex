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

  @valid_params [:spider, :state, :startts, :endts, :has_tag, :lacks_tag]

  @spec count(String.t, String.t, Keyword.t, Keyword.t) :: ScrapyCloudEx.result
  def count(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
    make_request(api_key, project_id, params, opts, @valid_params, "count")
  end

  @spec list(String.t, String.t | integer, Keyword.t, Keyword.t) :: ScrapyCloudEx.result
  def list(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
    valid_params = @valid_params ++ [:format, :count, :start, :stop, :key]
    make_request(api_key, project_id, params |> set_default_format(), opts, valid_params, "list")
  end

  @spec make_request(String.t, String.t | integer, Keyword.t, Keyword.t, [atom, ...], String.t) :: ScrapyCloudEx.result
  defp make_request(api_key, project_id, params, opts, valid_params, endpoint) do
    params = params |> Helpers.canonicalize_params(@param_synonyms)

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

  @spec set_default_format(Keyword.t) :: Keyword.t
  defp set_default_format(params), do: Keyword.put_new(params, :format, @default_format)
end
