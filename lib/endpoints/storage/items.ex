defmodule SHEx.Endpoints.Storage.Items do
  require Logger
  import SHEx.Endpoints.Guards

  alias SHEx.Endpoints.{Helpers, Storage}
  alias SHEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/items"

  def get(api_key, composite_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id)
      when is_list(params)
      when is_list(opts) do
        with valid_params <- [:item_index, :field_name, :format, :meta, :nodata] ++ Storage.all_params(),
         :ok <- Helpers.validate_params(params, valid_params),
         :ok <- Storage.validate_format(params |> Keyword.get(:format)),
         item_index <- Keyword.get(params, :item_index, ""),
         {:item_index, :ok} <- {:item_index, validate_optional_param_type(item_index, &(is_integer(&1) || is_binary(&1)))},
         field_name <- Keyword.get(params, :field_name, ""),
         {:field_name, :ok} <- {:field_name, validate_optional_param_type(item_index, &is_binary/1)} do
      base_url =
        [@base_url, composite_id, item_index, field_name]
        |> Enum.reject(& &1 == "")
        |> merge_sections()

      pagination_params =
        params
        |> Enum.filter(fn {k, _} -> Enum.member?(Storage.pagination_params(), k) end)
        |> warn_on_empty_pagination_params()

      query = URI.encode_query(pagination_params)

      url = "#{base_url}?#{query}"

      RequestConfig.new()
      |> Map.put(:api_key, api_key)
      |> Map.put(:opts, opts)
      |> Map.put(:url, url)
      # |> Map.put(:headers, [{:"Accept", "application/json"}])
      |> Helpers.make_request()
    else
      {:item_index, :error} -> {:error, {:invalid_param, {:item_index, "item index must be an integer or a string"}}}
      {:field_name, :error} -> {:error, {:invalid_param, {:field_name, "field name must be a string"}}}
    end
  end

  def stats(api_key, composite_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id)
      when is_list(opts) do
    RequestConfig.new()
    |> Map.put(:api_key, api_key)
    |> Map.put(:opts, opts)
    |> Map.put(:url, [@base_url, composite_id, "stats"] |> merge_sections())
    |> Helpers.make_request()
  end

  defp merge_sections(sections), do: sections |> Enum.join("/")

  defp validate_optional_param_type("", _), do: :ok
  defp validate_optional_param_type(param, validator) do
    if validator.(param) do
      :ok
    else
      :error
    end
  end

  defp warn_on_empty_pagination_params([_ | _] = params), do: params
  defp warn_on_empty_pagination_params([]) do
    Logger.warn("#{__MODULE__}.get/4 called without pagination params")
    []
  end
end
