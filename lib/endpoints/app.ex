defmodule SHEx.Endpoints.App do
  @pagination_params [:count, :offset]

  def pagination_params(), do: @pagination_params
end
