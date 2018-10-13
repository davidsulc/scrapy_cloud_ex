defmodule ScrapyCloudEx.Endpoints.HelpersTest do
  use ExUnit.Case, async: true

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  defmodule Adapter do
    @behaviour ScrapyCloudEx.HttpAdapter

    @impl ScrapyCloudEx.HttpAdapter
    def request(_), do: {:ok, :ok}

    @impl ScrapyCloudEx.HttpAdapter
    def handle_response(_response, opts), do: opts
  end

  test "opts are forwarded to HttpAdapter's handle_response/2 function" do
    request =
      RequestConfig.new()
      |> RequestConfig.put(:url, "localhost:8080/get")
      |> RequestConfig.merge_opts(foo: :bar)
      |> RequestConfig.merge_opts(http_adapter: Adapter)

    opts = Helpers.make_request(request)

    assert Keyword.get(opts, :foo) == :bar
  end
end
