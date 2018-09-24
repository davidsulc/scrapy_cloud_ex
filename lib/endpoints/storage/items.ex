defmodule SHEx.Endpoints.Storage.Items do
  import SHEx.Endpoints.Guards

  alias SHEx.Endpoints.Helpers
  alias SHEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/items"

  def stats(api_key, project_id, spider_id, job_id, opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(spider_id)
      when is_id(job_id)
      when is_list(opts) do
    complete_job_id = [project_id, spider_id, job_id] |> to_complete_job_id()
    stats(api_key, complete_job_id, opts)
  end

  def stats(api_key, complete_job_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(complete_job_id)
      when is_list(opts) do
    RequestConfig.new()
    |> Map.put(:api_key, api_key)
    |> Map.put(:opts, opts)
    |> Map.put(:url, "#{@base_url}/#{complete_job_id}/stats")
    |> Helpers.make_request()
  end

  def to_complete_job_id([project_id, spider_id, job_id]), do: "#{project_id}/#{spider_id}/#{job_id}"
end
