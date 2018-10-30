defmodule ScrapyCloudEx.Endpoints.Storage do
  @moduledoc """
  Documents commonalities between all storage endpoint-related functions.

  ## Format option

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
  def meta_params(), do: [:_key, :_ts]

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
