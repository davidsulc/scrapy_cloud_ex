defmodule SHEx.Endpoints.App.Jobs do
  alias SHEx.HttpAdapters.Default, as: DefaultAdapter
  alias SHEx.HttpAdapter.RequestData

  def delete(api_key, project_id, jobs, opts \\ []) do
    http_client = get_http_client(opts)
    base_url = "https://app.scrapinghub.com/api"
    data = %RequestData{body: jobs |> Enum.map(&{:job, &1})}
    http_client.request(:post, api_key, "#{base_url}/jobs/delete.json?project=#{project_id}", data, opts)
  end

  defp get_http_client(opts) do
    opts |> Keyword.get(:http_adapter, DefaultAdapter)
  end
end
