defmodule SHEx.Endpoints.App.Jobs do
  import SHEx.Endpoints.Guards

  alias SHEx.HttpAdapters.Default, as: DefaultAdapter
  alias SHEx.HttpAdapter.RequestConfig

  @base_url "https://app.scrapinghub.com/api"
  @valid_update_params [:add_tag, :remove_tag]

  def update(api_key, project_id, job_or_jobs, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_project_id(project_id)
      when is_job_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(params)
      when is_list(opts) do
    with :ok <- validate_update_params(params) do
      request = prepare_basic_request(api_key, project_id, job_or_jobs, opts)

      request
      |> Map.put(:url, "#{@base_url}/jobs/update.json")
      |> Map.put(:body, request.body ++ params)
      |> make_request()
    else
      {:invalid_params, params} -> {:error, {:invalid_params, {params, "valid params: #{inspect(@valid_update_params)}"}}}
    end
  end

  def delete(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_project_id(project_id)
      when is_job_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    prepare_basic_request(api_key, project_id, job_or_jobs, opts)
    |> Map.put(:url, "#{@base_url}/jobs/delete.json")
    |> make_request()
  end

  def stop(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_project_id(project_id)
      when is_job_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    prepare_basic_request(api_key, project_id, job_or_jobs, opts)
    |> Map.put(:url, "#{@base_url}/jobs/stop.json")
    |> make_request()
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

  defp make_request(%RequestConfig{opts: opts} = config) do
    http_client = get_http_client(opts)

    config |> http_client.request()
  end

  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end

  defp validate_update_params(params) do
    params
    |> Enum.reject(fn {k, _} -> Enum.member?(@valid_update_params, k) end)
    |> case do
      [] -> :ok
      invalid_params -> {:invalid_params, Keyword.keys(invalid_params)}
    end
  end
end
