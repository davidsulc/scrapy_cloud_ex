defmodule ScrapyCloudEx.Endpoints.Storage.Logs do
  @moduledoc """
  Wraps the [Logs](https://doc.scrapinghub.com/api/logs.html) endpoint.

  The logs API lets you work with logs from your crawls.
  """

  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.Endpoints.Storage.QueryParams
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://storage.scrapinghub.com/logs"

  @typedoc """
  Integer log level.

  | Value | Log level |
  | ----- | --------- |
  | 10    | DEBUG     |
  | 20    | INFO      |
  | 30    | WARNING   |
  | 40    | ERROR     |
  | 50    | CRITICAL  |
  """
  @type log_level :: 10 | 20 | 30 | 40 | 50

  @typedoc """
  A log object.

  Map with the following keys:

  * `"message"` - the log message (`t:String.t/0`).
  * `"level"` - the integer log level (`t:log_level/0`).
  * `"time"` - the UNIX timestamp of the message, in milliseconds (`t:integer/0`).
  """
  @type log_object :: %{ required(String.t()) => integer() | String.t() | log_level() }

  @doc """
  Retrieves logs for a given job.

  The `composite_id` must have at least 3 sections (i.e. refer to a job).

  See docs [here](https://doc.scrapinghub.com/api/logs.html#logs-project-id-spider-id-job-id).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.Storage.Logs.get("API_KEY", "14/13/12")
  ```
  """
  @spec get(String.t(), String.t(), Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result([log_object()])
  def get(api_key, composite_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(params)
      when is_list(opts) do
    with %QueryParams{error: nil} = query_params <- params |> QueryParams.from_keywords() do
      query_string = query_params |> QueryParams.to_query()
      base_url = [@base_url, composite_id] |> Enum.join("/")

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
end
