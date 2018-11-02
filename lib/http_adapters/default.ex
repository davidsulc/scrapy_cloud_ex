defmodule ScrapyCloudEx.HttpAdapters.Default do
  @moduledoc """
  A default implementation of the `ScrapyCloudEx.HttpAdapter` behaviour.

  Depends on `:hackney`.
  """

  @behaviour ScrapyCloudEx.HttpAdapter

  require Logger

  alias ScrapyCloudEx.HttpAdapter
  alias ScrapyCloudEx.HttpAdapter.{Helpers, RequestConfig, Response}

  @impl ScrapyCloudEx.HttpAdapter
  @spec request(RequestConfig.t()) :: {:ok, Response.t()} | ScrapyCloudEx.tagged_error()
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
  @spec handle_response(Response.t(), Keyword.t()) ::
          {:ok, any} | {:error, HttpAdapter.error_map()}
  def handle_response(%Response{status: status, headers: headers, body: body}, opts) do
    format = Helpers.get_format(headers)
    Logger.debug("decode format set to #{format}")
    decoder_fun = opts |> Keyword.fetch!(:decoder) |> Helpers.get_decoder_fun()

    body
    |> decode_body(decoder_fun, format)
    |> case do
      {:ok, decoded_body} -> format_api_result(status, decoded_body)
      {:error, message} -> format_response_error(status, message)
    end
  end

  @spec make_request(atom, String.t(), String.t(), [tuple], [tuple], Keyword.t()) ::
          {:ok, Response.t()} | ScrapyCloudEx.tagged_error()
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

  @spec decode_body(String.t(), ScrapyCloudEx.Decoder.decoder_function(), atom) ::
          {:ok, any} | ScrapyCloudEx.tagged_error()
  defp decode_body(body, decoder_fun, format) do
    body
    |> decoder_fun.(format)
    |> case do
      {:error, _} = error -> error
      {:ok, _} = result -> result
    end
  end

  @spec format_api_result(integer, String.t()) :: {:ok, any} | {:error, HttpAdapter.error_map()}
  defp format_api_result(200, body), do: {:ok, body}
  defp format_api_result(status, %{message: message}), do: format_response_error(status, message)
  defp format_api_result(status, body), do: format_response_error(status, body)

  @spec format_message(any) :: any
  defp format_message(message) when is_binary(message), do: message |> String.trim()
  defp format_message(%{"message" => message}), do: format_message(message)
  defp format_message(message), do: message

  @spec format_response_error(integer, any) :: {:error, HttpAdapter.error_map()}
  defp format_response_error(status, message) do
    {:error, %{status: status, message: format_message(message)}}
  end

  @spec format_body(list) :: String.t() | {:form, list}
  defp format_body([]), do: ""
  defp format_body(list) when is_list(list), do: {:form, list}
end
