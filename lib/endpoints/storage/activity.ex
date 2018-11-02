defmodule ScrapyCloudEx.Endpoints.Storage.Activity do
  @moduledoc """
  Retrieve project events.

  Scrapinghub keeps track of certain project events such as when spiders
  are run or new spiders are deployed. This activity log can be accessed
  in the dashboard by clicking on Activity in the left sidebar, or
  programmatically through the API in this module.
  """

  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.Endpoints.Storage.QueryParams
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/activity"

  @default_format :json

  @param_aliases [
    {:p_count, :pcount}
  ]

  @doc """
  Retrieves messages for the specified project.

  Results are returned in reverse order.

  The following parameters are supported in the `params` argument:

    * `:count` - maximum number of results to return.

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs [here](https://doc.scrapinghub.com/api/activity.html#activity-project-id) (GET only).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.Storage.Activity.list("API_KEY", "123", count: 10)
  ```
  """
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

  @doc """
  Retrieves messages for multiple projects.

  Results are returned in reverse order.

  The following parameters are supported in the `params` argument:

    * `:format` - the format to be used for returning results. Must be one of
      `:json`, `:csv`, `:jl`, `:xml`. Defaults to `:json`. See more about formats
      in `ScrapyCloudEx.Endpoints.Storage`.

    * `:p` - project id. May be given multiple times.

    * `:count` - maximum number of results to return in total.

    * `:pcount` - maximum number of results to return per project.

    * `:meta` - meta parameter to add to each result. Supported values:

      * `:_project` - the project id.

      * `:_ts` - timestamp in milliseconds for when the message was added.

    * `:pagination` - supports the `:count` value. See more about pagination
      in `ScrapyCloudEx.Endpoints.Storage`.

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs [here](https://doc.scrapinghub.com/api/activity.html#activity-projects).

  ## Example

  ```
  params = [p: "123", p: "456", count: 100, pcount: 15, meta: [:_ts, :_project]]
  ScrapyCloudEx.Endpoints.Storage.Activity.projects("API_KEY", params)
  ```
  """
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
