defmodule ScrapyCloudEx.Endpoints.Storage.Items do
  require Logger
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.Endpoints.Storage.QueryParams
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/items"

  def get(api_key, composite_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(params)
      when is_list(opts) do
    with %QueryParams{error: nil} = query_params <- params |> QueryParams.from_keywords() do
      if section_count(composite_id) < 4 do
        query_params |> QueryParams.warn_if_no_pagination("#{__MODULE__}.get/4 ")
      end

      query_string = query_params |> QueryParams.to_query()

      base_url = [@base_url, composite_id] |> merge_sections()

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:url, "#{base_url}?#{query_string}")
      |> RequestConfig.put(:headers, Keyword.get(opts, :headers, []))
      |> RequestConfig.merge_opts(opts)
      |> Helpers.make_request()
    else
      %QueryParams{error: error} -> {:error, error}
      error -> {:error, error}
    end
  end

  def stats(api_key, composite_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id)
      when is_list(opts) do
    RequestConfig.new()
    |> RequestConfig.put(:api_key, api_key)
    |> RequestConfig.merge_opts(opts)
    |> RequestConfig.put(:url, [@base_url, composite_id, "stats"] |> merge_sections())
    |> Helpers.make_request()
  end

  defp section_count(id), do: id |> String.split("/") |> Enum.reject(&(&1 == "")) |> length()

  defp merge_sections(sections), do: sections |> Enum.join("/")
end
