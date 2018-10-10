defmodule ScrapyCloudEx.IntegrationTest.HttpAdapter do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, async: true

      alias ScrapyCloudEx.HttpAdapter.RequestConfig, as: RC

      setup_all do
        adapter = unquote(opts |> Keyword.get(:adapter))

        request =
          RC.new()
          |> RC.put(:url, "localhost:8080/post")
          |> RC.put(:method, :post)
          |> RC.merge_opts(decoder: fn
            "", :json -> {:ok, %{}}
            x, :json -> Jason.decode(x)
          end)

        [adapter: adapter, request: request]
      end

      describe "requests" do
        test "are successful", %{adapter: adapter, request: request} do
          assert {:ok, _} = adapter.request(request)
        end

        test "use HTTP Basic authentication", %{adapter: adapter, request: request} do
          key = "API_KEY"
          {:ok, response} = adapter.request(request |> RC.put(:api_key, key))
          base_64_auth = "#{key}:" |> Base.encode64()
          assert response["headers"]["authorization"] == "Basic #{base_64_auth}"
        end

        test "add included headers", %{adapter: adapter, request: request} do
          request = request |> RC.put(:headers, [{"x-foo", "bar"}, {:another, :header}])
          {:ok, response} = adapter.request(request)
          assert(response["headers"]["x-foo"] == "bar")
          assert response["headers"]["another"] == "header"
        end

        test "add included body", %{adapter: adapter, request: request} do
          request = request |> RC.put(:body, [{"foo", "bar"}, {:another, :body}])
          {:ok, response} = adapter.request(request)
          assert response["form"]["foo"] == "bar"
          assert response["form"]["another"] == "body"
        end

        test "call the provided decoder with the given decoder_format", %{adapter: adapter, request: request} do
          decoder = fn _, :some_format ->
            send(self(), :decoder_called)
            {:ok, "decoded_body"}
          end

          request = request |> RC.merge_opts([decoder: decoder, decoder_format: :some_format])
          adapter.request(request)
          assert_receive :decoder_called
        end

        test "return an error tuple if unsuccessful", %{adapter: adapter, request: request} do
          assert {:error, _} = adapter.request(request |> RC.put(:url, "localhost:8080/status/500"))
        end
      end
    end
  end
end
