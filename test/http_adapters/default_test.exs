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

  describe "Http@adapter.request/1: GET requests" do
    test "are successful" do
      request = get_request()
      assert {:ok, _} = @adapter.request(request)
    end

    test "use HTTP Basic authentication" do
      key = "API_KEY"
      base_64_auth = "#{key}:" |> Base.encode64()

      response =
        get_request()
        |> RequestConfig.put(:api_key, key)
        |> @adapter.request()
        |> extract_and_decode()

      assert response["headers"]["authorization"] == "Basic #{base_64_auth}"
    end

    test "add included headers" do
      response =
        get_request()
        |> RequestConfig.put(:headers, [{"x-foo", "bar"}, {:another, :header}])
        |> @adapter.request()
        |> extract_and_decode()

      assert(response["headers"]["x-foo"] == "bar")
      assert response["headers"]["another"] == "header"
    end
  end
end
