defmodule ScrapyCloudEx.HttpAdapter.Helpers do
  def get_format([]), do: :text
  def get_format([{"Content-Type", "application/json"<>_} | _]), do: :json
  def get_format([{"Content-Type", "application/x-jsonlines"<>_} | _]), do: :jl
  def get_format([{"Content-Type", "application/xml"<>_} | _]), do: :xml
  def get_format([{"Content-Type", "text/csv"<>_} | _]), do: :csv
  def get_format([{"Content-Type", "text/html"<>_} | _]), do: :html
  def get_format([{"Content-Type", "text/plain"<>_} | _]), do: :text
  def get_format([_ | t]), do: get_format(t)

  def get_decoder_fun(decoder_fun) when is_function(decoder_fun), do: decoder_fun

  def get_decoder_fun(decoder_module) when is_atom(decoder_module),
    do: &decoder_module.decode(&1, &2)
end
