defmodule ScrapingHubEx.Endpoints.Storage.Activity do
  import ScrapingHubEx.Endpoints.Guards

  alias ScrapingHubEx.Endpoints.Helpers
  alias ScrapingHubEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/activity"

  @default_format :json

  @param_synonyms [
    {:p_count, :pcount},
  ]

  def list(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
    params = params |> set_default_format()

    with :ok <- Helpers.validate_params(params, [:count, :format]) do
      base_url = [@base_url, project_id] |> Enum.join("/")
      query_string = URI.encode_query(params)

      RequestConfig.new()
      |> Map.put(:api_key, api_key)
      |> Map.put(:url, "#{base_url}?#{query_string}")
      |> Map.put(:headers, Keyword.get(opts, :headers, []))
      |> Map.put(:opts, opts |> Keyword.put(:decoder_format, :json))
      |> Helpers.make_request()
    else
      error -> {:error, error}
    end
  end

  defp set_default_format(params) do
    case Keyword.get(params, :format) do
      nil -> Keyword.put(params, :format, @default_format)
      _ -> params
    end
  end
end
