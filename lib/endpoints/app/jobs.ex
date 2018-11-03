defmodule ScrapyCloudEx.Endpoints.App.Jobs do
  @moduledoc """
  Wraps the [Jobs](https://doc.scrapinghub.com/api/jobs.html) endpoint.

  The jobs API makes it easy to work with your spider’s jobs and lets you schedule,
  stop, update and delete them.
  """

  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.{App, Helpers}
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @typep encoder_fun :: (any -> {:ok, any} | {:error, any})

  @base_url "https://app.scrapinghub.com/api"
  @valid_states ~w(pending running finished deleted)

  @doc """
  Schedules a job for a given spider.

  The following parameters are supported in the `params` argument:

    * `:add_tag` - add the specified tag to the job. May be given multiple times.

    * `:job_settings` - job settings to be proxied to the job. This value should be provided
        as a string representation of a JSON object. If it is provided as a map, an attempt
        will be made to encode it using `Jason`.

    * `:priority` - job priority. Supports values in the `0..4` range (where `4` is highest
        priority). Defaults to `2`.

    * `:units` - Amount of [units](https://support.scrapinghub.com/support/solutions/articles/22000200408-what-is-a-scrapy-cloud-unit-) to use for the job. Supports values in the `1..6` range.

  Any other parameter will be treated as a spider argument.

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs [here](https://doc.scrapinghub.com/api/jobs.html#run-json).

  ## Example

  ```
  settings = [job_settings: ~s({ "SETTING1": "value1", "SETTING2": "value2" })]
  tags = [add_tag: "sometag", add_tag: "othertag"]
  params = [priority: 3, units: 1, spiderarg1: "example"] ++ tags ++ settings
  ScrapyCloudEx.Endpoints.App.Jobs.run("API_KEY", "123", "somespider", params)
  # {:ok, %{"jobid" => "123/1/4", "status" => "ok"}}
  ```
  """
  @spec run(String.t(), String.t() | integer, String.t(), Keyword.t(), Keyword.t()) ::
          ScrapyCloudEx.result(map())
  def run(api_key, project_id, spider_name, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_binary(spider_name)
      when is_list(params)
      when is_list(opts) do
    job_settings = params |> Keyword.get(:job_settings)
    json_encoder = opts |> get_encoder()

    with {:ok, job_settings} <- format_job_settings(job_settings, json_encoder) do
      body =
        params
        |> Keyword.put(:project, project_id)
        |> Keyword.put(:spider, spider_name)
        |> maybe_add_job_settings(job_settings)

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:method, :post)
      |> RequestConfig.put(:body, body)
      |> RequestConfig.put(:opts, opts)
      |> RequestConfig.put(:url, "#{@base_url}/run.json")
      |> Helpers.make_request()
    else
      error -> {:error, error}
    end
  end

  @doc """
  Retrieves job information for a given project, spider, or specific job.

  The following parameters are supported in the `params` argument:

    * `:format` - the format to be used for returning results. Can be `:json` or `:jl`. Defaults to `:json`.

    * `:job` - the job id.

    * `:spider` - the spider name.

    * `:state` - return jobs with specified state. Supported values: `"pending"`, `"running"`,
        `"finished"`, `"deleted"`.

    * `:has_tag` - return jobs with specified tag. May be given multiple times, and will behave
        as a logical `OR` operation among the values.

    * `:lacks_tag` - return jobs that lack specified tag. May be given multiple times, and will
        behave as a logical `AND` operation among the values.

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs [here](https://doc.scrapinghub.com/api/jobs.html#jobs-list-json-jl).

  ## Examples

  ```
  # Retrieve the latest 3 finished jobs for "somespider" spider
  params = [spider: "somespider", state: "finished", count: 3]
  ScrapyCloudEx.Endpoints.App.Jobs.list("API_KEY", "123", params)

  # Retrieve all running jobs
  ScrapyCloudEx.Endpoints.App.Jobs.list("API_KEY", "123", state: "running")

  # Retrieve all jobs with the tag "consumed"
  ScrapyCloudEx.Endpoints.App.Jobs.list("API_KEY", "123", has_tag: "consumed")
  ```

  ## Example return value

  ```
  {:ok,
     %{
       "status" => "ok",
       "count" => 2,
       "total" => 2,
       "jobs" => [
         %{
           "close_reason" => "cancelled",
           "elapsed" => 124138,
           "errors_count" => 0,
           "id" => "123/1/3",
           "items_scraped" => 620,
           "logs" => 17,
           "priority" => 2,
           "responses_received" => 670,
           "spider" => "somespider",
           "spider_type" => "manual",
           "started_time" => "2018-10-03T07:06:07",
           "state" => "finished",
           "tags" => ["foo"],
           "updated_time" => "2018-10-03T07:07:42",
           "version" => "5ef3139-master"
         },
         %{
           "close_reason" => "cancelled",
           "elapsed" => 483843779,
           "errors_count" => 1,
           "id" => "123/1/2",
           "items_scraped" => 2783,
           "logs" => 20,
           "priority" => 3,
           "responses_received" => 2888,
           "spider" => "somespider",
           "spider_args" => %{"spiderarg1" => "example"},
           "spider_type" => "manual",
           "started_time" => "2018-10-23T16:42:54",
           "state" => "finished",
           "tags" => ["bar", "foo"],
           "updated_time" => "2018-10-23T16:45:54",
           "version" => "5ef3139-master"
         }
       ]
     }
   }
  ```
  """
  @spec list(String.t(), String.t() | integer, Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result(map())
  def list(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_list(params)
      when is_list(opts) do
    with valid_params =
           [:format, :job, :spider, :state, :has_tag, :lacks_tag] ++ App.pagination_params(),
         :ok <- Helpers.validate_params(params, valid_params),
         true <- Keyword.get(params, :format) in [nil, :json, :jl],
         format = Keyword.get(params, :format, :json),
         :ok <- params |> Keyword.get(:state) |> validate_state() do
      params = params |> Keyword.delete(:format)
      query = [{:project, project_id} | params] |> URI.encode_query()

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:opts, opts)
      |> RequestConfig.put(:url, "#{@base_url}/jobs/list.#{format}?#{query}")
      |> Helpers.make_request()
    else
      false ->
        error =
          "expected format to be one of :json, :jl, but got `#{Keyword.get(params, :format)}`"
          |> Helpers.invalid_param_error(:format)

        {:error, error}

      {:invalid_param, _} = error ->
        {:error, error}
    end
  end

  @doc """
  Updates information about jobs.

  The job ids in `job_or_jobs` must have at least 3 sections.

  The following parameters are supported in the `params` argument:

    * `:add_tag` - add specified tag to the job(s). May be given multiple times.

    * `:remove_tag` - remove specified tag to the job(s). May be given multiple times.

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs [here](https://doc.scrapinghub.com/api/jobs.html#jobs-update-json).

  ## Example

  ```
  params = [add_tag: "foo", add_tag: "bar", remove_tag: "sometag"]
  ScrapyCloudEx.Endpoints.App.Jobs.update("API_KEY", "123", ["123/1/1", "123/1/2"], params)
  # {:ok, %{"count" => 2, "status" => "ok"}}
  ```
  """
  @spec update(String.t(), String.t() | integer, String.t() | [String.t()], Keyword.t(), Keyword.t()) ::
          ScrapyCloudEx.result(map())
  def update(api_key, project_id, job_or_jobs, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(params)
      when is_list(opts) do
    with :ok <- Helpers.validate_params(params, [:add_tag, :remove_tag]) do
      request = prepare_basic_post_request(api_key, project_id, job_or_jobs, opts)

      request
      |> RequestConfig.put(:url, "#{@base_url}/jobs/update.json")
      |> RequestConfig.put(:body, request.body ++ params)
      |> Helpers.make_request()
    else
      {:invalid_param, _} = error -> {:error, error}
    end
  end

  @doc """
  Deletes one or more jobs.

  The job ids in `job_or_jobs` must have at least 3 sections.

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs [here](https://doc.scrapinghub.com/api/jobs.html#jobs-delete-json<Paste>).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.App.Jobs.delete("API_KEY", "123", ["123/1/1", "123/1/2"])
  # {:ok, %{"count" => 2, "status" => "ok"}}
  ```
  """
  @spec delete(String.t(), String.t() | integer, String.t() | [String.t()], Keyword.t()) ::
          ScrapyCloudEx.result(map())
  def delete(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    api_key
    |> prepare_basic_post_request(project_id, job_or_jobs, opts)
    |> RequestConfig.put(:url, "#{@base_url}/jobs/delete.json")
    |> Helpers.make_request()
  end

  @doc """
  Stops one or more running jobs.

  The job ids in `job_or_jobs` must have at least 3 sections.

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs [here](https://doc.scrapinghub.com/api/jobs.html#jobs-stop-json).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.App.Jobs.stop("API_KEY", "123", ["123/1/1", "123/1/2"])
  # {:ok, %{"status" => "ok"}}
  ```
  """
  @spec stop(String.t(), String.t() | integer, [String.t()], Keyword.t()) ::
          ScrapyCloudEx.result(map())
  def stop(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    api_key
    |> prepare_basic_post_request(project_id, job_or_jobs, opts)
    |> RequestConfig.put(:url, "#{@base_url}/jobs/stop.json")
    |> Helpers.make_request()
  end

  @spec prepare_basic_post_request(String.t(), String.t() | integer, [String.t()], Keyword.t()) ::
          RequestConfig.t()
  defp prepare_basic_post_request(api_key, project_id, job_or_jobs, opts) do
    body =
      job_or_jobs
      |> format_jobs()
      |> Keyword.put(:project, project_id)

    RequestConfig.new()
    |> RequestConfig.put(:api_key, api_key)
    |> RequestConfig.put(:method, :post)
    |> RequestConfig.put(:body, body)
    |> RequestConfig.put(:opts, opts)
  end

  @spec format_jobs([String.t()]) :: Keyword.t()
  defp format_jobs(job_or_jobs) do
    job_or_jobs
    |> List.wrap()
    |> Enum.map(&{:job, &1})
  end

  @spec get_encoder(Keyword.t()) :: encoder_fun | nil
  defp get_encoder(opts) do
    opts
    |> Keyword.get(:encoder)
    |> case do
      nil -> get_default_encoder(opts)
      encoder -> encoder
    end
  end

  @spec get_default_encoder(Keyword.t()) :: encoder_fun | nil
  defp get_default_encoder(opts) do
    with true <- Keyword.get(opts, :encoder_fallback, true),
         true <- function_exported?(Jason, :encode, 2) do
      &Jason.encode(&1, [])
    else
      _ -> nil
    end
  end

  @spec format_job_settings(any, encoder_fun | nil) :: ScrapyCloudEx.result(any)

  defp format_job_settings(nil, _encoder), do: {:ok, []}

  defp format_job_settings(settings, _encoder) when is_binary(settings), do: {:ok, settings}

  defp format_job_settings(settings, _encoder = nil) when is_map(settings) do
    "job_settings must be provided as a string-encoded JSON object, or a JSON encoder must be provided as an option (falling back to Jason unsuccessful)"
    |> Helpers.invalid_param_error(:job_settings)
  end

  defp format_job_settings(settings, encoder) when is_map(settings), do: encoder.(settings)

  defp format_job_settings(_settings, _encoder) do
    "expected job_settings to be a string-encoded JSON object or a map"
    |> Helpers.invalid_param_error(:job_settings)
  end

  @spec maybe_add_job_settings(Keyword.t(), any) :: Keyword.t()

  defp maybe_add_job_settings(list, []), do: list

  defp maybe_add_job_settings(list, settings) do
    list |> Keyword.put(:job_settings, settings)
  end

  @spec validate_state(any) :: :ok | ScrapyCloudEx.tagged_error()

  defp validate_state(nil), do: :ok

  defp validate_state(state) when state in @valid_states, do: :ok

  defp validate_state(state),
    do:
      "state '#{state}' not among valid states: #{@valid_states |> Enum.join(", ")}"
      |> Helpers.invalid_param_error(:state)
end
