defmodule ScrapyCloudEx.Endpoints.Storage do
  alias ScrapyCloudEx.Endpoints.Helpers

  @spec pagination_params() :: [atom, ...]
  def pagination_params(), do: [:count, :index, :start, :startafter]

  @spec csv_params() :: [atom, ...]
  def csv_params(), do: [:fields, :include_headers, :sep, :quote, :escape, :lineend]

  @spec meta_params() :: [atom, ...]
  def meta_params(), do: [:_key, :_ts]

  @valid_formats [:json, :jl, :xml, :csv, :text, :html]

  @spec validate_format(any) :: :ok | {:invalid_param, {atom, any}}

  def validate_format(nil), do: :ok

  def validate_format(format) when format in @valid_formats, do: :ok

  def validate_format(format) do
    "expected format '#{inspect(format)}' to be one of: #{inspect(@valid_formats)}"
    |> Helpers.invalid_param_error(:format)
  end
end
