defmodule Test.Support.URI do
  @moduledoc false

  def get_query(url) when is_binary(url) do
    url
    |> URI.parse()
    |> Map.get(:query)
  end

  def query_to_map(query) do
    query
    |> URI.query_decoder()
    |> Enum.reduce(%{}, fn {k, v}, acc -> add_to_query_map(acc, k, v) end)
  end

  def equivalent?(query_string, params) when is_binary(query_string) and is_list(params) do
    query_map = query_string |> query_to_map()
    params = params |> flatten_params()

    reduce_while_equivalent = fn key, _acc ->
      given_values = get_values_as_strings(params, key)
      query_values = query_map |> Map.get("#{key}") |> List.wrap()

      if given_values -- query_values == [] && query_values -- given_values == [] do
        {:cont, :ok}
      else
        {:halt, :not_equivalent}
      end
    end

    params
    |> Keyword.keys()
    |> Enum.reduce_while(:ok, reduce_while_equivalent)
    |> case do
      :ok -> true
      _ -> false
    end
  end

  def equivalent?(params, query_string) when is_list(params) and is_binary(query_string) do
    equivalent?(query_string, params)
  end

  def flatten_params(params) when is_list(params) do
    params
    |> Enum.map(&flatten_param/1)
    |> List.flatten()
  end

  defp flatten_param({_, v} = param) when is_list(v) do
    case hd(v) do
      # pagination: [count: 3]
      # csv: [fields: ["level"]]
      {_, _} -> v
      # meta: [:_key]
      _ -> param
    end
  end

  defp flatten_param(param), do: param

  defp add_to_query_map(map, k, v) do
    case Map.get(map, k) do
      nil -> Map.put(map, k, v)
      value -> Map.put(map, k, [v | value |> List.wrap()])
    end
  end

  defp get_values_as_strings(params, key) do
    params
    |> Keyword.get_values(key)
    |> List.flatten()
    |> Enum.map(&stringify_value/1)
  end

  defp stringify_value(values) when is_list(values) do
    values |> Enum.map(&stringify_value/1)
  end

  defp stringify_value(v), do: "#{v}"
end
