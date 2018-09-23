defmodule SHEx.Endpoints.App.Jobs do
  import SHEx.Endpoints.Guards

  alias SHEx.HttpAdapters.Default, as: DefaultAdapter
  alias SHEx.HttpAdapter.RequestConfig

  @base_url "https://app.scrapinghub.com/api"

  def delete(api_key, project_id, jobs, opts \\ [])
      when is_api_key(api_key)
      when is_project_id(project_id)
      when is_list(jobs)
      when is_list(opts) do
    RequestConfig.new()
    |> Map.put(:api_key, api_key)
    |> Map.put(:url, "#{@base_url}/jobs/delete.json?project=#{project_id}")
    |> Map.put(:method, :post)
    |> Map.put(:body, jobs |> Enum.map(&{:job, &1}))
    |> Map.put(:opts, opts)
    |> make_request()
  end

  def stop(api_key, project_id, jobs, opts \\ [])
      when is_api_key(api_key)
      when is_project_id(project_id)
      when is_list(jobs)
      when is_list(opts) do
    RequestConfig.new()
    |> Map.put(:api_key, api_key)
    |> Map.put(:url, "#{@base_url}/jobs/stop.json?project=#{project_id}")
    |> Map.put(:method, :post)
    |> Map.put(:body, jobs |> Enum.map(&{:job, &1}))
    |> Map.put(:opts, opts)
    |> make_request()
  end

  defp make_request(%RequestConfig{opts: opts} = config) do
    http_client = get_http_client(opts)

    config |> http_client.request()
  end

  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end
end
