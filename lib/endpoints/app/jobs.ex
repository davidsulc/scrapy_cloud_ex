defmodule SHEx.Endpoints.App.Jobs do
  import SHEx.Endpoints.Guards

  alias SHEx.Endpoints.{App, Helpers}
  alias SHEx.HttpAdapter.RequestConfig

  @base_url "https://app.scrapinghub.com/api"
  @valid_states ~w(pending running finished deleted)
  @valid_update_params [:add_tag, :remove_tag]
  @valid_list_params [:job, :spider, :state, :has_tag, :lacks_tag]

  def run(api_key, project_id, spider_name, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_binary(spider_name)
      when is_list(params)
      when is_list(opts) do
    with job_settings <- params |> Keyword.get(:job_settings),
         json_encoder <- opts |> Keyword.get(:json_encoder),
         {:ok, job_settings} <- format_job_settings(job_settings, json_encoder) do
      body =
        params
        |> Keyword.put(:project, project_id)
        |> Keyword.put(:spider, spider_name)
        |> maybe_add_job_settings(job_settings)

      RequestConfig.new()
      |> Map.put(:api_key, api_key)
      |> Map.put(:method, :post)
      |> Map.put(:body, body)
      |> Map.put(:opts, opts)
      |> Map.put(:url, "#{@base_url}/run.json")
      |> Helpers.make_request()
    else
      error -> {:error, error}
    end
  end

  def list(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_list(params)
      when is_list(opts) do
    with :ok <- Helpers.validate_params(params, @valid_list_params ++ App.pagination_params()),
         :ok <- params |> Keyword.get(:state) |> validate_state() do
      query = [{:project, project_id} | params] |> URI.encode_query()

      RequestConfig.new()
      |> Map.put(:api_key, api_key)
      |> Map.put(:opts, opts)
      |> Map.put(:url, "#{@base_url}/jobs/list.json?#{query}")
      |> Helpers.make_request()
    else
      {:invalid_params, _} = error -> {:error, error}
    end
  end

  def update(api_key, project_id, job_or_jobs, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(params)
      when is_list(opts) do
    with :ok <- Helpers.validate_params(params, @valid_update_params) do
      request = prepare_basic_request(api_key, project_id, job_or_jobs, opts)

      request
      |> Map.put(:url, "#{@base_url}/jobs/update.json")
      |> Map.put(:body, request.body ++ params)
      |> Helpers.make_request()
    else
      {:invalid_params, _} = error -> {:error, error}
    end
  end

  def delete(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    prepare_basic_request(api_key, project_id, job_or_jobs, opts)
    |> Map.put(:url, "#{@base_url}/jobs/delete.json")
    |> Helpers.make_request()
  end

  def stop(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    prepare_basic_request(api_key, project_id, job_or_jobs, opts)
    |> Map.put(:url, "#{@base_url}/jobs/stop.json")
    |> Helpers.make_request()
  end

  defp prepare_basic_request(api_key, project_id, job_or_jobs, opts) do
    body =
      job_or_jobs
      |> format_jobs()
      |> Keyword.put(:project, project_id)

    RequestConfig.new()
    |> Map.put(:api_key, api_key)
    |> Map.put(:method, :post)
    |> Map.put(:body, body)
    |> Map.put(:opts, opts)
  end

  defp format_jobs(job_or_jobs) do
    job_or_jobs
    |> List.wrap()
    |> Enum.map(&{:job, &1})
  end

  defp format_job_settings(nil, _encoder), do: {:ok, []}

  defp format_job_settings(settings, _encoder) when is_binary(settings), do: settings

  defp format_job_settings(settings, _encoder = nil) when is_map(settings) do
    if function_exported?(Jason, :encode, 2) do
      format_job_settings(settings, &Jason.encode(&1, []))
    else
      {:invalid_params,
       {:unencoded_job_settings_without_encoder,
        "job_settings must be provided as a string-encoded JSON object, or a JSON encoder must be provided as an option (falling back to Jason unsuccessful)"}}
    end
  end

  # TODO: document that encoder must return {:ok, encoded_json} on success
  defp format_job_settings(settings, encoder) when is_map(settings), do: encoder.(settings)

  defp format_job_settings(_settings, _encoder) do
    {:invalid_params,
     {:job_settings, "expected job_settings to be a string-encoded JSON object or a map"}}
  end

  defp maybe_add_job_settings(list, []), do: list

  defp maybe_add_job_settings(list, settings) do
    list |> Keyword.put(:job_settings, settings)
  end

  defp validate_state(nil), do: :ok
  defp validate_state(state) when state in @valid_states, do: :ok

  defp validate_state(state),
    do:
      {:invalid_params,
       {:invalid_state,
        "state '#{state}' not among valid states: #{@valid_states |> Enum.join(", ")}"}}
end
