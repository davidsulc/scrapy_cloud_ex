defmodule SHEx.Endpoints.Storage do
  def pagination_params(), do: [:count, :index, :start, :startafter]

  def csv_params(), do: [:fields, :include_headers, :sep, :quote, :escape, :lineend]

  def meta_params(), do: [:_key, :_ts]

  def all_params() do
    pagination_params() ++ csv_params() ++ meta_params()
  end

  @valid_formats [:json, :jl, :xml, :csv, :text]
  def validate_format(nil), do: :ok
  def validate_format(format) when format in @valid_formats, do: :ok
  def validate_format(format), do: {:invalid_param, {:format, "expected format '#{format}' to be one of: #{@valid_formats}"}}
end
