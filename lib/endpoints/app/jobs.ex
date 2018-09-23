defmodule SHEx.Endpoints.App.Jobs do
  import SHEx.Endpoints.Guards

  alias SHEx.HttpAdapters.Default, as: DefaultAdapter
  alias SHEx.HttpAdapter.RequestConfig

  @base_url "https://app.scrapinghub.com/api"

  def delete(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_project_id(project_id)
      when is_job_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    prepare_stop_or_delete_request(api_key, project_id, job_or_jobs, opts)
    |> Map.put(:url, "#{@base_url}/jobs/delete.json")
    |> make_request()
  end

  def stop(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_project_id(project_id)
      when is_job_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    prepare_stop_or_delete_request(api_key, project_id, job_or_jobs, opts)
    |> Map.put(:url, "#{@base_url}/jobs/stop.json")
    |> make_request()
  end

  defp prepare_stop_or_delete_request(api_key, project_id, job_or_jobs, opts) do
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
end
