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
      query_string =
        query_params
        |> warn_if_no_pagination(composite_id)
        |> QueryParams.to_query()

      base_url = [@base_url, composite_id] |> merge_sections()
      opts = opts |> Helpers.set_default_decoder_format(Keyword.get(params, :format))

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

  defp maps_to_single_item?(id) do
    id
    |> String.split("/")
    |> List.last()
    |> String.match?(~r"^\d+$")
  end

  defp warn_if_no_pagination(%QueryParams{} = query_params, id) when is_binary(id) do
      case section_count(id) do
        4 -> if !maps_to_single_item?(id), do: warn_if_no_pagination(query_params)

        count when count < 4 -> warn_if_no_pagination(query_params)

        _count -> :ok
      end

      query_params
  end

  defp warn_if_no_pagination(%QueryParams{} = query_params) do
    query_params |> QueryParams.warn_if_no_pagination("#{__MODULE__}.get/4")
  end

  defp section_count(id), do: id |> String.split("/") |> Enum.reject(&(&1 == "")) |> length()

  defp merge_sections(sections), do: sections |> Enum.join("/")
end
