defmodule ScrapyCloudEx.HttpAdapters.DefaultTest.CommonTests do
  import ExUnit.Assertions

  alias ScrapyCloudEx.HttpAdapter.{RequestConfig, Response}

  @adapter ScrapyCloudEx.HttpAdapters.Default

  def build_request(verb) when is_atom(verb) do
    RequestConfig.new()
    |> RequestConfig.put(:url, "localhost:8080/#{verb}")
    |> RequestConfig.put(:method, verb)
  end

  def extract_ok({:ok, response}), do: response

  def common_request_tests(request_key) do
    module = __MODULE__
    quote bind_quoted: [module: module, request_key: request_key] do
      test "are successful", %{request_key => request} do
        module.test_success(request)
      end

      test "use HTTP Basic authentication", %{request_key => request} do
        module.test_http_auth(request)
      end

      test "add included headers", %{request_key => request} do
        module.test_included_headers(request)
      end
    end
  end

  def test_success(request) do
    assert {:ok, _} = @adapter.request(request)
  end

  def test_http_auth(request) do
    key = "API_KEY"
    base_64_auth = "#{key}:" |> Base.encode64()

    response =
      request
      |> RequestConfig.put(:api_key, key)
      |> @adapter.request()
      |> extract_and_decode()

    assert response["headers"]["authorization"] == "Basic #{base_64_auth}"
  end

  def test_included_headers(request) do
    response =
      request
      |> RequestConfig.put(:headers, [{"x-foo", "bar"}, {:another, :header}])
      |> @adapter.request()
      |> extract_and_decode()

    assert response["headers"]["x-foo"] == "bar"
    assert response["headers"]["another"] == "header"
  end

  def test_included_body(request) do
    response =
      request
      |> RequestConfig.put(:body, [foo: :bar, another: :param])
      |> @adapter.request()
      |> extract_and_decode()

    assert response["form"]["foo"] == "bar"
    assert response["form"]["another"] == "param"
  end

  defp extract_and_decode(request_config) do
    request_config
    |> extract_ok()
    |> decode_response()
    |> extract_ok()
  end

  defp decode_response(%Response{body: body}), do: Jason.decode(body)
end

defmodule ScrapyCloudEx.HttpAdapters.DefaultTest do
  use ExUnit.Case, async: true

  import ScrapyCloudEx.HttpAdapters.DefaultTest.CommonTests,
      only: [build_request: 1, common_request_tests: 1, test_included_body: 1, extract_ok: 1]

  alias ScrapyCloudEx.HttpAdapter.Response

  @adapter ScrapyCloudEx.HttpAdapters.Default
  @decoder_opts [decoder: ScrapyCloudEx.Decoders.Default]

  setup_all do
    response = %Response{
      status: 200,
      headers: [{"Content-Type", "application/json; charset=UTF-8"}],
      body: ""
    }

    [:get, :post, :put, :delete]
    |> Enum.map(&{:"#{&1}_request", build_request(&1)})
    |> Keyword.put(:response, response)
  end

  describe "request/1: GET requests" do
    common_request_tests(:get_request)
  end

  describe "request/1: POST requests" do
    common_request_tests(:post_request)

    test "add included body", %{post_request: request} do
      test_included_body(request)
    end
  end

  describe "request/1: PUT requests" do
    common_request_tests(:put_request)

    test "add included body", %{put_request: request} do
      test_included_body(request)
    end
  end

  describe "request/1: DELETE requests" do
    common_request_tests(:delete_request)
  end

  describe "handle_response/2" do
    test "generic success response", %{response: response} do
      body = %{"foo" => "bar"}
      {:ok, encoded_body} = Jason.encode(body)
      {:ok, decoded_body} = @adapter.handle_response(%{response | status: 200, body: encoded_body}, @decoder_opts)
      assert Map.equal?(body, decoded_body)
    end

    test "401 Unauthorized response", %{response: response} do
			# happens when providing an invalid API key when making a request
      body = "need at least one project that a user has permission to view\n"
      assert {:error, error} = @adapter.handle_response(%{response | status: 400, headers: [], body: body}, @decoder_opts)
      assert Map.equal?(error, %{message: body |> String.trim(), status: 400})
		end

    test "400 Bad Request response in json format", %{response: response} do
      # e.g. "API_KEY" |> ScrapyCloudEx.Endpoints.App.Jobs.list("123")
      body = "{\"status\": \"badrequest\", \"message\": \"User 'johndoe' doesn't have access to project 123\"}"
      assert {:error, error} = @adapter.handle_response(%{response | status: 400, body: body}, @decoder_opts)
      assert Map.equal?(error, %{message: "User 'johndoe' doesn't have access to project 123", status: 400})
    end

    test "400 Bad Request response without format", %{response: response} do
      # e.g. "API_KEY" |> ScrapyCloudEx.Endpoints.Storage.Activity.projects([p: 123])
      body = "Unauthorized\n"
      assert {:error, error} = @adapter.handle_response(%{response | status: 401, headers: [], body: body}, @decoder_opts)
      assert Map.equal?(error, %{message: body |> String.trim(), status: 401})
    end

    test "json response", %{response: response} do
      # e.g. "API_KEY" |> ScrapyCloudEx.Endpoints.App.Jobs.list("12345", count: 2)
			body = """
        {
          "status": "ok",
          "count": 2,
          "total": 2,
          "jobs": [
            {
              "close_reason": "cancelled",
              "elapsed": 604745891,
              "errors_count": 0,
              "id": "12345/1/23",
              "items_scraped": 1941,
              "logs": 18,
              "priority": 3,
              "responses_received": 1996,
              "spider": "some_spider",
              "spider_args": {"spider_arg_a": "a", "spider_arg_b": "b"},
              "spider_type": "manual",
              "started_time": "2018-10-06T10:04:27",
              "state": "finished",
              "tags": ["tag_a", "tag_b"],
              "updated_time": "2018-10-06T10:06:16",
              "version": "9ef24562-master"
            },
            {
              "close_reason": "cancelled",
              "elapsed": 605171306,
              "errors_count": 0,
              "id": "12345/1/19",
              "items_scraped": 0,
              "priority": 1,
              "responses_received": 0,
              "spider": "some_other_spider",
              "spider_args": {"spider_arg_a": "a", "spider_arg_b": "b"},
              "spider_type": "manual",
              "state": "finished",
              "tags": ["tag_1", "tag_2"],
              "version": "9ef24562-master"
            }
          ]
        }
			"""
      assert {:ok, decoded_body} = @adapter.handle_response(%{response | body: body}, @decoder_opts)
      assert Map.equal?(decoded_body, body |> Jason.decode() |> extract_ok())
		end

    test "jl response", %{response: response} do
      # e.g. "API_KEY" |> ScrapyCloudEx.Endpoints.App.Jobs.list("12345", count: 2, format: :jl)
			body = """
        {"status": "ok"}\n
        {
          "close_reason": "cancelled",
          "elapsed": 604745891,
          "errors_count": 0,
          "id": "12345/1/23",
          "items_scraped": 1941,
          "logs": 18,
          "priority": 3,
          "responses_received": 1996,
          "spider": "some_spider",
          "spider_args": {"spider_arg_a": "a", "spider_arg_b": "b"},
          "spider_type": "manual",
          "started_time": "2018-10-06T10:04:27",
          "state": "finished",
          "tags": ["tag_a", "tag_b"],
          "updated_time": "2018-10-06T10:06:16",
          "version": "9ef24562-master"
        }\n
        {
          "close_reason": "cancelled",
          "elapsed": 605171306,
          "errors_count": 0,
          "id": "12345/1/19",
          "items_scraped": 0,
          "priority": 1,
          "responses_received": 0,
          "spider": "some_other_spider",
          "spider_args": {"spider_arg_a": "a", "spider_arg_b": "b"},
          "spider_type": "manual",
          "state": "finished",
          "tags": ["tag_1", "tag_2"],
          "version": "9ef24562-master"
        }\n
			"""
      response = %{response | headers: [{"Content-Type", "application/x-jsonlines"}], body: body}
      decoder_opts = [decoder: fn _body, :jl -> {:ok, :decoded_jl} end]
      assert {:ok, :decoded_jl} = @adapter.handle_response(response, decoder_opts)
		end

    test "xml response", %{response: response} do
      # e.g. "API_KEY" |> ScrapyCloudEx.Endpoints.Storage.Logs.get("12345/1/23/3", pagination: [count: 1], format: :xml)
      body = """
        <?xml version="1.0" encoding="UTF-8"?>
        <value>
           <array>
              <data>
                 <value>
                    <struct>
                       <member>
                          <name>time</name>
                          <value>
                             <int>1538820271724</int>
                          </value>
                       </member>
                       <member>
                          <name>level</name>
                          <value>
                             <int>20</int>
                          </value>
                       </member>
                       <member>
                          <name>message</name>
                          <value>
                             <string>[scrapy.utils.log] Overridden settings: {'NEWSPIDER_MODULE': 'some_scraper.spiders', 'STATS_CLASS': 'sh_scrapy.stats.HubStorageStatsCollector', 'ROBOTSTXT_OBEY': True, 'LOG_LEVEL': 'INFO', 'SPIDER_MODULES': ['some_scraper.spiders'], 'AUTOTHROTTLE_ENABLED': True, 'LOG_ENABLED': False, 'MEMUSAGE_LIMIT_MB': 950, 'BOT_NAME': 'some_scraper', 'TELNETCONSOLE_HOST': '0.0.0.0'}</string>
                          </value>
                       </member>
                    </struct>
                 </value>
              </data>
           </array>
        </value>
      """
      response = %{response | headers: [{"Content-Type", "application/xml"}], body: body}
      decoder_opts = [decoder: fn _body, :xml -> {:ok, :decoded_xml} end]
      assert {:ok, :decoded_xml} = @adapter.handle_response(response, decoder_opts)
    end

    test "text response", %{response: response} do
      # e.g. "API_KEY" |> ScrapyCloudEx.Endpoints.Storage.Items.get("12345/1/23/3/some_field", format: :text)
      response = %{response | headers: [{"Content-Type", "text/plain"}], body: "foo bar"}
      decoder_opts = [decoder: fn _body, :text -> {:ok, :decoded_text} end]
      assert {:ok, :decoded_text} = @adapter.handle_response(response, decoder_opts)
		end

    test "html response", %{response: response} do
      # e.g. "API_KEY" |> ScrapyCloudEx.Endpoints.Storage.Items.get("12345/1/23/3/some_field", format: :html)
      response = %{response | headers: [{"Content-Type", "text/html"}], body: "<div><p>foo</p><p>bar</p></div>"}
      decoder_opts = [decoder: fn _body, :html -> {:ok, :decoded_html} end]
      assert {:ok, :decoded_html} = @adapter.handle_response(response, decoder_opts)
		end

    test "no response type treated as text", %{response: response} do
      response = %{response | headers: [{"Content-Type", "text/plain"}], body: "foo bar"}
      decoder_opts = [decoder: fn _body, :text -> {:ok, :decoded_text} end]
      assert {:ok, :decoded_text} = @adapter.handle_response(response, decoder_opts)
		end
  end
end
