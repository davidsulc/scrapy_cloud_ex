defmodule ScrapyCloudEx.HttpAdapters.Default do
  @behaviour ScrapyCloudEx.HttpAdapter

  require Logger

  alias ScrapyCloudEx.HttpAdapter.{Helpers, RequestConfig, Response}

  @impl ScrapyCloudEx.HttpAdapter
  def request(%RequestConfig{
        method: method,
        api_key: key,
        url: url,
        headers: headers,
        body: body,
        opts: opts
      }) do
    case make_request(method, key, url, headers, body, opts) do
      {:ok, _} = result -> result
      error -> {:error, error}
    end
  end

  @impl ScrapyCloudEx.HttpAdapter
  def handle_response(%Response{status: status, headers: headers, body: body}, opts) do
    format = Helpers.get_format(headers)
    Logger.debug("decode format set to #{format}")
    decoder_fun = Keyword.fetch!(opts, :decoder) |> Helpers.get_decoder_fun()

    body
    |> decode_body(decoder_fun, format)
    |> case do
      {:ok, decoded_body} -> format_api_result(status, decoded_body)
      {:error, message} -> format_response_error(status, message)
    end
  end

  defp make_request(type, api_key, url, headers, body, opts) do
    result =
      :hackney.request(type, url, headers, format_body(body), [
        {:basic_auth, {api_key, ""}} | opts
      ])

    with {:ok, status, headers, client} <- result,
         {:ok, body} <- :hackney.body(client) do
      {:ok, %Response{status: status, headers: headers, body: body}}
    else
      {:error, error} -> error
    end
  end

  defp decode_body(body, decoder_fun, format) do
    body
    |> decoder_fun.(format)
    |> case do
      {:error, _} = error -> error
      {:ok, _} = result -> result
    end
  end

  defp format_api_result(200, body), do: {:ok, body}
  defp format_api_result(status, %{message: message}), do: format_response_error(status, message)
  defp format_api_result(status, body), do: format_response_error(status, body)

  defp format_message(message) when is_binary(message), do: message |> String.trim()
  defp format_message(%{"message" => message}), do: format_message(message)
  defp format_message(message), do: message

  defp format_response_error(status, message) do
    {:error, %{status: status, message: format_message(message)}}
  end

  defp format_body([]), do: ""
  defp format_body(list) when is_list(list), do: {:form, list}
end
