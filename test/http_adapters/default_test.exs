defmodule ScrapyCloudEx.HttpAdapters.DefaultTest do
  use ExUnit.Case, async: true

  alias ScrapyCloudEx.HttpAdapter.{RequestConfig, Response}

  @adapter ScrapyCloudEx.HttpAdapters.Default

  defp build_request(verb) when is_atom(verb) do
    RequestConfig.new()
    |> RequestConfig.put(:url, "localhost:8080/#{verb}")
    |> RequestConfig.put(:method, verb)
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

  defp test_included_body(request) do
    response =
      request
      |> RequestConfig.put(:body, [foo: :bar, another: :param])
      |> @adapter.request()
      |> extract_and_decode()

    assert response["form"]["foo"] == "bar"
    assert response["form"]["another"] == "param"
  end

  setup_all do
    [:get, :post, :put, :delete]
    |> Enum.map(&{:"#{&1}_request", build_request(&1)})
  end

  describe "request/1: GET requests" do
    test "are successful", %{get_request: request} do
      test_success(request)
    end

    test "use HTTP Basic authentication", %{get_request: request} do
      test_http_auth(request)
    end

    test "add included headers", %{get_request: request} do
      test_included_headers(request)
    end
  end

  describe "request/1: POST requests" do
    test "are successful", %{post_request: request} do
      test_success(request)
    end

    test "use HTTP Basic authentication", %{post_request: request} do
      test_http_auth(request)
    end

    test "add included headers", %{post_request: request} do
      test_included_headers(request)
    end

    test "add included body", %{post_request: request} do
      test_included_body(request)
    end
  end

  describe "request/1: PUT requests" do
    test "are successful", %{put_request: request} do
      test_success(request)
    end

    test "use HTTP Basic authentication", %{put_request: request} do
      test_http_auth(request)
    end

    test "add included headers", %{put_request: request} do
      test_included_headers(request)
    end

    test "add included body", %{put_request: request} do
      test_included_body(request)
    end
  end

  describe "request/1: DELETE requests" do
    test "are successful", %{put_request: request} do
      test_success(request)
    end

    test "use HTTP Basic authentication", %{put_request: request} do
      test_http_auth(request)
    end

    test "add included headers", %{put_request: request} do
      test_included_headers(request)
    end
  end
end
