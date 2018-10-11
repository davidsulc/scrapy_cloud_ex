defmodule ScrapyCloudEx.HttpAdapters.Default do
  @behaviour ScrapyCloudEx.HttpAdapter

  alias ScrapyCloudEx.HttpAdapter.RequestConfig

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

  defp make_request(type, api_key, url, headers, body, opts) do
    result =
      :hackney.request(type, url, headers, format_body(body), [
        {:basic_auth, {api_key, ""}} | opts
      ])

    with {:ok, status, _headers, client} <- result,
         {:ok, body} <- :hackney.body(client) do
      body
      |> decode_body(opts)
      |> case do
        {:error, %{data: message}} -> %{status: status, message: format_message(message)}
        {:ok, decoded_body} -> format_api_result(status, decoded_body)
      end
    else
      {:error, error} -> error
    end
  end

  defp decode_body(body, opts) do
    format = Keyword.fetch!(opts, :decoder_format)
    decoder_fun = Keyword.fetch!(opts, :decoder) |> get_decoder_fun()

    decoder_fun.(body, format)
  end

  defp get_decoder_fun(decoder_fun) when is_function(decoder_fun), do: decoder_fun

  defp get_decoder_fun(decoder_module) when is_atom(decoder_module),
    do: &decoder_module.decode(&1, &2)

  defp format_api_result(200, body), do: {:ok, body}
  defp format_api_result(status, %{message: message}), do: %{status: status, message: format_message(message)}
  defp format_api_result(status, body), do: %{status: status, message: format_message(body)}

  defp format_message(message) when is_binary(message), do: message |> String.trim()
  defp format_message(%{"message" => message}), do: format_message(message)
  defp format_message(message), do: message

  defp format_body([]), do: ""
  defp format_body(list) when is_list(list), do: {:form, list}
end
