defmodule ScrapyCloudEx.Endpoints.App.Comments do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://app.scrapinghub.com/api/comments"

  def get(api_key, composite_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(opts) do
    RequestConfig.new()
    |> Map.put(:api_key, api_key)
    |> Map.put(:opts, opts |> Keyword.put(:decoder_format, :json))
    |> Map.put(:url, [@base_url, composite_id] |> Enum.join("/"))
    |> Helpers.make_request()
  end

  def post(api_key, composite_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(params)
      when is_list(opts) do
    with :ok <- Helpers.validate_params(params, [:text]),
         true <- split_sections(composite_id) > 3 do
      RequestConfig.new()
      |> Map.put(:api_key, api_key)
      |> Map.put(:method, :post)
      |> Map.put(:body, params)
      |> Map.put(:opts, opts |> Keyword.put(:decoder_format, :json))
      |> Map.put(:url, [@base_url, composite_id] |> Enum.join("/"))
      |> Helpers.make_request()
    else
      {:invalid_param, _} = error -> {:error, error}
      false -> {:error, {:invalid_param, {:composite_id, "expected id to contain at least 4 sections"}}}
    end
  end

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

  defp split_sections(composite), do: composite |> String.split("/")
end
