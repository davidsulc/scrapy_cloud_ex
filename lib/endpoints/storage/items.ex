defmodule ScrapyCloudEx.Endpoints.Storage.Items do
  @moduledoc """
  Wraps the [Items](https://doc.scrapinghub.com/api/items.html) endpoint.

  The Items API lets you interact with the items stored in the hubstorage backend for your projects.
  """

  require Logger
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.Endpoints.Storage.QueryParams
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @typedoc """
  A scraped item.

  Map with the following (optional) keys:

  * `"_type"` - the item definition (`t:String.t/0`).
  * `"_template"` - the template matched against. Portia only.
  * `"_cached_page_id"` - cached page ID. Used to identify the scraped page in storage.

  Scraped fields will be top level alongside the internal fields listed above.
  """
  @type item_object :: %{required(String.t()) => any()}

  @base_url "https://storage.scrapinghub.com/items"

  @doc """
  Retrieve items for a project, spider, or job.

  The following parameters are supported in the `params` argument:

    * `:format` - the [format](ScrapyCloudEx.Endpoints.Storage.html#module-format) to be used
        for returning results. Can be `:json`, `:xml`, `:csv`, or `:jl`. Defaults to `:json`.

    * `:meta` - [meta parameters](ScrapyCloudEx.Endpoints.Storage.html#module-meta-parameters) to show.

    * `:nodata` - if set, no data will be returned other than specified `:meta` keys.

    * `:pagination` - [pagination parameters](ScrapyCloudEx.Endpoints.Storage.html#module-pagination)

  Please always use pagination parameters (`:start`, `:startafter`, and `:count`) to limit amount of
  items in response to prevent timeouts and different performance issues. A warning will be logged if
  the `composite_id` doesn't refers to more than a single item and no pagination parameters were provided.

  The `opts` value is documented [here](ScrapyCloudEx.Endpoints.html#module-options).

  See docs [here](https://doc.scrapinghub.com/api/items.html#items-project-id-spider-id-job-id-item-no-field-name) (GET only).

  ## Examples

  Retrieve all items from a given job
  ```
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7")
  ```

  Retrive first item from a given job
  ```
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7/0")
  ```

  Retrieve values from a single field
  ```
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7/fieldname")
  ```

  Retrieve all items from a given spider
  ```
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34")
  ```

  Retrieve all items from a given project
  ```
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53")
  ```

  ## Pagination examples

  Retrieve first 10 items from a given job
  ```
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7", pagination: [count: 10])
  ```

  Retrieve 10 items from a given job starting from the 20th item
  ```
  pagination = [count: 10, start: "53/34/7/20"]
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7", pagination: pagination)
  ```

  Retrieve 10 items from a given job starting from the item following to the given one
  ```
  pagination = [count: 10, startafter: "53/34/7/19"]
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7", pagination: pagination)
  ```

  Retrieve a few items from a given job by their IDs
  ```
  pagination = [index: 5, index: 6]
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7", pagination: pagination)
  ```

  ## Get items in a specific format

  ```
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7/0", format: :json)
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7/0", format: :jl)
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7/0", format: :xml)

  params = [format: :csv, csv: [fields: ~w(some_field some_other_field)]]
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7/0", params)
  ```

  ## Get meta field from items

  To get only metadata from items, pass the `nodata: true` parameter along with the meta field
  that you want to get.

  ```
  ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7/0", meta: [:_key], nodata: true)
  ```
  """
  @spec get(String.t(), String.t(), Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result([item_object()])
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

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:url, "#{base_url}?#{query_string}")
      |> RequestConfig.put(:headers, Keyword.get(opts, :headers, []))
      |> RequestConfig.put(:opts, opts)
      |> Helpers.make_request()
    else
      %QueryParams{error: error} -> {:error, error}
      error -> {:error, error}
    end
  end

  @doc """
  Retrieves the item stats for a given job.

  The `composite_id` must have 3 sections (i.e. refer to a job).

  The response will contain the following information:

  | Field                 | Description                              |
  | --------------------- | ---------------------------------------- |
  | `counts[field]`       | The number of times the field occurs.    |
  | `totals.input_bytes`  | The total size of all requests in bytes. |
  | `totals.input_values` | The total number of requests.            |

  The `opts` value is documented [here](ScrapyCloudEx.Endpoints.html#module-options).

  See docs [here](https://doc.scrapinghub.com/api/items.html#items-project-id-spider-id-job-id-stats).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.Storage.Items.stats("API_KEY", "14/13/12")
  ```
  """
  @spec stats(String.t(), String.t(), Keyword.t()) :: ScrapyCloudEx.result(map())
  def stats(api_key, composite_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id)
      when is_list(opts) do
    RequestConfig.new()
    |> RequestConfig.put(:api_key, api_key)
    |> RequestConfig.put(:opts, opts)
    |> RequestConfig.put(:url, [@base_url, composite_id, "stats"] |> merge_sections())
    |> Helpers.make_request()
  end

  @spec maps_to_single_item?(String.t()) :: boolean
  defp maps_to_single_item?(id) do
    id
    |> String.split("/")
    |> List.last()
    |> String.match?(~r"^\d+$")
  end

  @spec warn_if_no_pagination(QueryParams.t(), String.t()) :: QueryParams.t()
  defp warn_if_no_pagination(%QueryParams{} = query_params, id) when is_binary(id) do
    case section_count(id) do
      4 -> if !maps_to_single_item?(id), do: warn_if_no_pagination(query_params)
      count when count < 4 -> warn_if_no_pagination(query_params)
      _count -> :ok
    end

    query_params
  end

  @spec warn_if_no_pagination(QueryParams.t()) :: QueryParams.t()
  defp warn_if_no_pagination(%QueryParams{} = query_params) do
    query_params |> QueryParams.warn_if_no_pagination("#{__MODULE__}.get/4")
  end

  @spec section_count(String.t()) :: integer
  defp section_count(id), do: id |> String.split("/") |> Enum.reject(&(&1 == "")) |> length()

  @spec merge_sections([String.t()]) :: String.t()
  defp merge_sections(sections), do: sections |> Enum.join("/")
end
