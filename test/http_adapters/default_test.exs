defmodule ScrapyCloudEx.HttpAdapters.DefaultTest do
  use ExUnit.Case, async: true

  alias ScrapyCloudEx.HttpAdapter.{RequestConfig, Response}

  @adapter ScrapyCloudEx.HttpAdapters.Default

  defp get_request() do
    RequestConfig.new()
    |> RequestConfig.put(:url, "localhost:8080/get")
    |> RequestConfig.put(:method, :get)
  end

  defp extract_and_decode(request_config) do
    request_config
    |> extract_ok()
    |> decode_response()
    |> extract_ok()
  end

  defp extract_ok({:ok, response}), do: response

  defp decode_response(%Response{body: body}), do: Jason.decode(body)

  defp test_success(request) do
    assert {:ok, _} = @adapter.request(request)
  end

  defp test_http_auth(request) do
    key = "API_KEY"
    base_64_auth = "#{key}:" |> Base.encode64()

    response =
      request
      |> RequestConfig.put(:api_key, key)
      |> @adapter.request()
      |> extract_and_decode()

    assert response["headers"]["authorization"] == "Basic #{base_64_auth}"
  end

  defp test_included_headers(request) do
    response =
      request
      |> RequestConfig.put(:headers, [{"x-foo", "bar"}, {:another, :header}])
      |> @adapter.request()
      |> extract_and_decode()

    assert response["headers"]["x-foo"] == "bar"
    assert response["headers"]["another"] == "header"
  end

  describe "request/1: GET requests" do
    test "are successful" do
      get_request() |> test_success()
    end

    test "use HTTP Basic authentication" do
      get_request() |> test_http_auth()
    end

    test "add included headers" do
      get_request() |> test_included_headers()
    end
  end
end
