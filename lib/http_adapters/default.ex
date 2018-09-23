defmodule SHEx.HttpAdapters.Default do
  @behaviour SHEx.HttpAdapter

  alias SHEx.HttpAdapter.RequestConfig

  @impl SHEx.HttpAdapter
  def request(%RequestConfig{method: method, api_key: key, url: url, headers: headers, body: body, opts: opts}) do
    case make_request(method, key, url, headers, body, opts) do
      {:ok, _} = result -> result
      error -> {:error, error}
    end
  end

  defp make_request(type, api_key, url, headers, body, opts) do
    result =
      :hackney.request(type, url, headers, format_body(body), [
        {:basic_auth, {api_key, ""}} | opts
      ])

    with {:ok, status, _headers, client} <- result,
         {:ok, body} <- :hackney.body(client) do
      case Jason.decode(body) do
        {:error, error} -> {:json_error, error}
        {:ok, decoded_body} -> format_api_result(status, decoded_body)
      end
    else
      {:error, error} ->
        {:request_error, error}
    end
  end

  defp format_api_result(200, body), do: {:ok, body}
  defp format_api_result(status, body), do: {:api_error, {status, body}}

  defp format_body([]), do: ""
  defp format_body(list) when is_list(list), do: {:form, list}
end
