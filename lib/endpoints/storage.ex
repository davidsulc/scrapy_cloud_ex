defmodule ScrapyCloudEx.Endpoints.Storage do
  @moduledoc """
  Documents commonalities between all storage endpoint-related functions.

  ## Format

  The `:format` option given as an optional parameter must be one of
  `:json`, `:csv`, `:html`, `:jl`, `:text`, `:xml`. If none is given, it
  defaults to `:json`. Note that not all functions will accept all format
  values.

  ### CSV options

  When requesting results in CSV format with `format: :csv`, additional
  configuration parameters must be provided within the value associated
  to the `:csv` key:

  * `:fields` - required, list of binaries indicating the fields to include,
  in order from left to right.

  * `:include_headers` - optional, boolean indicating whether to include the
    header names in the first row.

  * `:sep` - optional, separator character to use between cells.

  * `:quote` - optional, quote character.

  * `:escape` - optional, escape character.

  * `:lineend` - line end string.

  #### Example

  ```
  params = [format: :csv, csv: [fields: ~w(foo bar), include_headers: true]]
  ```

  ## Pagination

  The `:pagination` option must be a keyword list containing pagination-relevant
  options. Note that not all functions will accept all pagination options.

  Providing pagination options outside of the `:pagination` keyword list will
  result in a warning.

  Parameters:

  * `:count` - number of results to provide.

  * `:start` - skip results before the given one. See a note about format below.

  * `:startafter` - return results after the given one. See a note about format below.

  * `:index` - a non-zero positive offset to retrieve specific records. May be
    provided multiple times.

  While the `index` parameter is just a short `<entity_id>` (ex: `[index: 4]`), `start`
  and `startafter` parameters should have the full form with 4 sections
  `<project_id>/<spider_id>/<job_id>/<entity_id>` (ex: `[start: "1/2/3/4"]`, `[startafter: "1/2/3/3"]`).

  ### Example

  ```
  params = [format: :json, pagination: [count: 100, index: 101]]
  ```

  ## Meta parameters

  You can use the `:meta` parameter to return metadata for the record in addition to its core data.
  The following values are available:

  * `:_key` - the item key in the format `:project_id/:spider_id/:job_id/:item_no` (`t:String.t/0`).
  * `:_project` - the project id (`t:integer/0`).
  * `:_ts` - timestamp in milliseconds for when the item was added (`t:integer/0`).

  ### Example

  ```
  params = [meta: [:_key, :_ts]]
  ```
  """

  alias ScrapyCloudEx.Endpoints.Helpers

  @doc false
  @spec pagination_params() :: [atom, ...]
  def pagination_params(), do: [:count, :index, :start, :startafter]

  @doc false
  @spec csv_params() :: [atom, ...]
  def csv_params(), do: [:fields, :include_headers, :sep, :quote, :escape, :lineend]

  @doc false
  @spec meta_params() :: [atom, ...]
  def meta_params(), do: [:_key, :_project, :_ts]

  @valid_formats [:json, :jl, :xml, :csv, :text, :html]

  @doc false
  @spec validate_format(any) :: :ok | {:invalid_param, {atom, any}}

  def validate_format(nil), do: :ok

  def validate_format(format) when format in @valid_formats, do: :ok

  def validate_format(format) do
    "expected format '#{inspect(format)}' to be one of: #{inspect(@valid_formats)}"
    |> Helpers.invalid_param_error(:format)
  end
end
