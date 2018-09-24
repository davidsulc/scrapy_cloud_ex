defmodule SHEx.Endpoints.Storage do
  def pagination_params(), do: [:count, :index, :start, :startafter]
  def csv_params(), do: [:fields, :include_headers, :sep, :quote, :escape, :lineend]
  def meta_params(), do: [:_key, :_ts]
end
