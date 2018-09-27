defmodule SHEx.Endpoints.Storage do
  alias SHEx.Endpoints.Helpers

  def pagination_params(), do: [:count, :index, :start, :startafter]

  def csv_params(), do: [:fields, :include_headers, :sep, :quote, :escape, :lineend]

  def meta_params(), do: [:_key, :_ts]

  @valid_formats [:json, :jl, :xml, :csv, :text]
  def validate_format(nil), do: :ok
  def validate_format(format) when format in @valid_formats, do: :ok
  def validate_format(format) do
    "expected format '#{inspect(format)}' to be one of: #{inspect(@valid_formats)}"
    |> Helpers.invalid_param_error(:format)
  end
end
