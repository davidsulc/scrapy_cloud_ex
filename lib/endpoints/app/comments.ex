defmodule ScrapyCloudEx.Endpoints.App.Comments do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://app.scrapinghub.com/api/comments"

  def stats(api_key, project_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id)
      when is_list(opts) do
    RequestConfig.new()
    |> Map.put(:api_key, api_key)
    |> Map.put(:opts, opts |> Keyword.put(:decoder_format, :json))
    |> Map.put(:url, [@base_url, project_id, "stats"] |> merge_sections())
    |> Helpers.make_request()
  end

  defp merge_sections(sections), do: sections |> Enum.join("/")
end
