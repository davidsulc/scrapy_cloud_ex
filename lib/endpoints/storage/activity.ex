defmodule ScrapyCloudEx.Endpoints.Storage.Activity do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.Endpoints.Storage.QueryParams
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/activity"

  @default_format :json

  @param_aliases [
    {:p_count, :pcount}
  ]

  @spec list(String.t(), String.t() | integer, Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result()
  def list(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
		count = Keyword.get(params, :count)
    params =
      params
      |> set_default_format()
      |> Keyword.delete(:count)

    case QueryParams.from_keywords(params) do
      %QueryParams{error: nil} = query_params ->
        base_url = [@base_url, project_id] |> Enum.join("/")
        query_string = QueryParams.to_query(query_params)

        query_string =
          if count do
            query_string <> "&count=#{count}"
          else
            query_string
          end

        RequestConfig.new()
        |> RequestConfig.put(:api_key, api_key)
        |> RequestConfig.put(:url, "#{base_url}?#{query_string}")
        |> RequestConfig.put(:headers, Keyword.get(opts, :headers, []))
        |> RequestConfig.put(:opts, opts)
        |> Helpers.make_request()

      %QueryParams{error: error} ->
        {:error, error}
    end
  end

  @spec projects(String.t(), Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result()
  def projects(api_key, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_list(params)
      when is_list(opts) do
    params =
      params
      |> set_default_format()
      |> Helpers.canonicalize_params(@param_aliases)

    p_vals = Keyword.get_values(params, :p) |> Enum.map(&{:p, &1})
    p_count = Keyword.get(params, :pcount)
    params = Keyword.drop(params, [:p, :pcount])

    case QueryParams.from_keywords(params) do
      %QueryParams{error: nil} = query_params ->
        base_url = [@base_url, "projects"] |> Enum.join("/")
        p_query = URI.encode_query(p_vals)
        p_count_query = if p_count, do: "pcount=#{p_count}", else: ""
        query_string = Enum.join([QueryParams.to_query(query_params), p_query, p_count_query], "&") |> IO.inspect()

        RequestConfig.new()
        |> RequestConfig.put(:api_key, api_key)
        |> RequestConfig.put(:url, "#{base_url}?#{query_string}")
        |> RequestConfig.put(:headers, Keyword.get(opts, :headers, []))
        |> RequestConfig.put(:opts, opts)
        |> Helpers.make_request()

      %QueryParams{error: error} ->
        {:error, error}
    end
  end

  @spec set_default_format(Keyword.t()) :: Keyword.t()
  defp set_default_format(params) do
    case Keyword.get(params, :format) do
      nil -> Keyword.put(params, :format, @default_format)
      _ -> params
    end
  end
end
