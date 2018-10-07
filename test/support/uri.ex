defmodule Test.Support.URI do
  def get_query(url) when is_binary(url) do
    url
    |> URI.parse()
    |> Map.get(:query)
    |> URI.query_decoder()
    |> Enum.reduce(%{}, fn {k, v}, acc -> add_to_query_map(acc, k, v) end)
  end

  defp add_to_query_map(map, k, v) do
    case Map.get(map, k) do
      nil -> Map.put(map, k, v)
      value -> Map.put(map, k, [v | value |> List.wrap()])
    end
  end
end
