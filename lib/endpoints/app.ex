defmodule ScrapyCloudEx.Endpoints.App do
  @spec pagination_params() :: [atom, ...]
  def pagination_params(), do: [:count, :offset]
end
