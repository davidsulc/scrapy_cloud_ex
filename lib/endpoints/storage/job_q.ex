defmodule ScrapyCloudEx.Endpoints.Storage.JobQ do
  @moduledoc """
  Wraps the [JobQ](https://doc.scrapinghub.com/api/jobq.html) endpoint.

  The JobQ API allows you to retrieve finished jobs from the queue.
  """

  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints
  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/jobq"

  @default_format :json

  @param_aliases [
    {:start_ts, :startts},
    {:end_ts, :endts}
  ]

  @valid_params [:spider, :state, :startts, :endts, :has_tag, :lacks_tag]

  @doc """
  Counts the jobs for the specified project.

  The following parameters are supported in the `params` argument:

    * `:spider` - the spider name.

    * `:state` - return jobs with specified state. Supported values: `"pending"`, `"running"`,
        `"finished"`, `"deleted"`.

    * `:startts` - UNIX timestamp at which to begin results, in milliseconds.

    * `:endts` - UNIX timestamp at which to end results, in milliseconds.

    * `:count` - limit results by a given number of jobs.

    * `:has_tag` - return jobs with specified tag. May be given multiple times, and will behave
        as a logical `OR` operation among the values.

    * `:lacks_tag` - return jobs that lack specified tag. May be given multiple times, and will
        behave as a logical `AND` operation among the values.

  The `opts` value is documented [here](ScrapyCloudEx.Endpoints.html#module-options).

  See docs [here](https://doc.scrapinghub.com/api/jobq.html#jobq-project-id-count).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.Storage.JobQ.count("API_KEY", "14", state: "running", has_tag: "sometag")
  # {:ok, 4}
  ```
  """
  @spec count(String.t(), String.t(), Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result(integer())
  def count(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
    make_request(api_key, project_id, params, opts, @valid_params, "count")
  end

  @doc """
  Lists the jobs for the specified project, in order from most recent to last.

  The following parameters are supported in the `params` argument:

    * `:format` - the [format](ScrapyCloudEx.Endpoints.Storage.html#module-format) to be used for
      returning results. Can be `:json` or `:jl`. Defaults to `:json`.

    * `:pagination` - the `:count` [pagination parameter](ScrapyCloudEx.Endpoints.Storage.html#module-pagination)
      is supported.

    * `:spider` - the spider name.

    * `:state` - return jobs with specified state. Supported values: `"pending"`, `"running"`,
        `"finished"`, `"deleted"`.

    * `:startts` - UNIX timestamp at which to begin results, in milliseconds.

    * `:endts` - UNIX timestamp at which to end results, in milliseconds.

    * `:start` - offset of initial jobs to skip in returned results.

    * `:end` - job key at which to stop showing results.

    * `:key` - job key for which to get job data. May be given multiple times.

    * `:has_tag` - return jobs with specified tag. May be given multiple times, and will behave
        as a logical `OR` operation among the values.

    * `:lacks_tag` - return jobs that lack specified tag. May be given multiple times, and will
        behave as a logical `AND` operation among the values.

  The `opts` value is documented [here](ScrapyCloudEx.Endpoints.html#module-options).

  See docs [here](https://doc.scrapinghub.com/api/jobq.html#jobq-project-id-list).

  ## List jobs finished between two timestamps

  If you pass the startts and endts parameters, the API will return only the jobs finished between them.

  ```
  ScrapyCloudEx.Endpoints.Storage.JobQ.list("API_KEY", 53, startts: 1359774955431, endts: 1359774955440)
  ```

  ## Retrieve jobs finished after some job

  JobQ returns the list of jobs, with the most recently finished first. It is recommended to associate
  the key of the most recently finished job with the downloaded data. When you want to update your data
  later on, you can list the jobs and stop at the previously downloaded job, through the `:stop` parameter.

  ```
  ScrapyCloudEx.Endpoints.Storage.JobQ.list("API_KEY", 53, stop: "53/7/81")
  ```

  ## Example return value

  ```
  {:ok, [
    %{
      "close_reason" => "cancelled",
      "elapsed" => 485061225,
      "errors" => 1,
      "finished_time" => 1540745154657,
      "items" => 2783,
      "key" => "345675/1/26",
      "logs" => 20,
      "pages" => 2888,
      "pending_time" => 1540744974169,
      "running_time" => 1540744974190,
      "spider" => "sixbid.com",
      "state" => "finished",
      "ts" => 1540745141316,
      "version" => "5ef2169-master"
    }
  ]}
  ```
  """
  @spec list(String.t(), String.t() | integer, Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result([map()])
  def list(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
    valid_params = @valid_params ++ [:format, :count, :start, :stop, :key, :pagination]
    params =
      params
      |> set_default_format()
			|> Endpoints.scope_params(:pagination, [:count])
      |> Endpoints.merge_scope(:pagination)

    make_request(api_key, project_id, params, opts, valid_params, "list")
  end

  @spec make_request(
          String.t(),
          String.t() | integer,
          Keyword.t(),
          Keyword.t(),
          [atom, ...],
          String.t()
        ) :: ScrapyCloudEx.result(any)
  defp make_request(api_key, project_id, params, opts, valid_params, endpoint) do
    params = params |> Helpers.canonicalize_params(@param_aliases)

    with :ok <- Helpers.validate_params(params, valid_params) do
      base_url = [@base_url, project_id, endpoint] |> Enum.join("/")
      query_string = URI.encode_query(params)

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:url, "#{base_url}?#{query_string}")
      |> RequestConfig.put(:headers, Keyword.get(opts, :headers, []))
      |> RequestConfig.put(:opts, opts)
      |> Helpers.make_request()
    else
      error -> {:error, error}
    end
  end

  @spec set_default_format(Keyword.t()) :: Keyword.t()
  defp set_default_format(params), do: Keyword.put_new(params, :format, @default_format)
end
