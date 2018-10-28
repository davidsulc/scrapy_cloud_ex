defmodule ScrapyCloudEx.Endpoints.App.Jobs do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.{App, Helpers}
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @typep encoder_fun :: (any -> {:ok, any} | {:error, any})

  @base_url "https://app.scrapinghub.com/api"
  @valid_states ~w(pending running finished deleted)

  @doc """
  Schedules a job for a given spider.

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs [here](https://doc.scrapinghub.com/api/jobs.html#run-json).

  The following parameters are supported in the `params` argument:

    * `add_tag` - add the specified tag to the job. May be given multiple times.

    * `job_settings` - job settings to be proxied to the job. This value should be provided
        as a string representation of a JSON object. If it is provided as a map, an attempt
        will be made to encode it using `Jason`.

    * `priority` - job priority. Supports values in the `0..4` range (where `4` is highest
        priority). Defaults to `2`.

    * `units` - Amount of [units](https://support.scrapinghub.com/support/solutions/articles/22000200408-what-is-a-scrapy-cloud-unit-) to use for the job. Supports values in the `1..6` range.

  Any other parameter will be treated as a spider argument.

  ## Example

  ```
  settings = [job_settings: ~s({ "SETTING1": "value1", "SETTING2": "value2" })]
  tags = [add_tag: "sometag", add_tag: "othertag"]
  params = [priority: 3, units: 1, spiderarg1: "example"] ++ tags ++ settings
  ScrapyCloudEx.Endpoints.App.Jobs.run("API_KEY", "123", "somespider", params)
  ```
  """
  @spec run(String.t(), String.t() | integer, String.t(), Keyword.t(), Keyword.t()) ::
          ScrapyCloudEx.result()
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

  @spec list(String.t(), String.t() | integer, Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result()
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

  @spec update(String.t(), String.t() | integer, [String.t()], Keyword.t(), Keyword.t()) ::
          ScrapyCloudEx.result()
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

  @spec delete(String.t(), String.t() | integer, [String.t()], Keyword.t()) ::
          ScrapyCloudEx.result()
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
  ```
  """
  @spec stop(String.t(), String.t() | integer, [String.t()], Keyword.t()) ::
          ScrapyCloudEx.result()
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

  @spec format_job_settings(any, encoder_fun | nil) :: ScrapyCloudEx.result()

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
