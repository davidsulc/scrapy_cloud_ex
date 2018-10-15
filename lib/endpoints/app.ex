defmodule ScrapyCloudEx.Endpoints.App do
  @moduledoc false

  @spec pagination_params() :: [atom, ...]
  def pagination_params(), do: [:count, :offset]
end
