defmodule SHEx.Endpoints.App.Jobs do
  alias SHEx.HttpAdapters.Default, as: DefaultAdapter
  alias SHEx.HttpAdapter.RequestConfig

  def delete(api_key, project_id, jobs, opts \\ [])
      when is_binary(api_key)
      when is_binary(project_id) or is_integer(project_id)
      when is_list(jobs)
      when is_list(opts) do
    base_url = "https://app.scrapinghub.com/api"
    http_client = get_http_client(opts)

    RequestConfig.new()
    |> Map.put(:api_key, api_key)
    |> Map.put(:url, "#{base_url}/jobs/delete.json?project=#{project_id}")
    |> Map.put(:method, :post)
    |> Map.put(:body, jobs |> Enum.map(&{:job, &1}))
    |> http_client.request()
  end

  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end
end
