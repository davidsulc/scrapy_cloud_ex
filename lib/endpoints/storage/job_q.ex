defmodule ScrapingHubEx.Endpoints.Storage.JobQ do
  import ScrapingHubEx.Endpoints.Guards

  alias ScrapingHubEx.Endpoints.Helpers
  alias ScrapingHubEx.HttpAdapter.RequestConfig

  @default_format :json

  @param_synonyms [
    {:start_ts, :startts},
    {:end_ts, :endts},
    {:hastag, :has_tag},
    {:lackstag, :lacks_tag}
  ]

  @base_url "https://storage.scrapinghub.com/jobq"

  def count(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
    valid_params = [:spider, :state, :startts, :endts, :has_tag, :lacks_tag]
    params = params |> Helpers.canonicalize_params(@param_synonyms)

    with :ok <- Helpers.validate_params(params, valid_params) do
      base_url = [@base_url, project_id, "count"] |> Enum.join("/")
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

  def list(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id) and project_id != ""
      when is_list(params)
      when is_list(opts) do
    params =
      params
      |> set_default_format()
      |> Helpers.canonicalize_params(@param_synonyms)

    valid_params = [:spider, :state, :startts, :endts, :start, :stop, :key, :has_tag, :lacks_tag, :format]

    with :ok <- Helpers.validate_params(params, valid_params) do
      base_url = [@base_url, project_id, "list"] |> Enum.join("/")
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
