defmodule Test.Support.URI do
  def get_query(url) when is_binary(url) do
    url
    |> URI.parse()
    |> Map.get(:query)
    |> URI.decode_query()
  end
end
