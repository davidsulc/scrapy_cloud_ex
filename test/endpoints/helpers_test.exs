defmodule ScrapyCloudEx.Endpoints.HelpersTest do
  use ExUnit.Case, async: true

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.HttpAdapter.{RequestConfig, Response}

  defmodule Adapter do
    @behaviour ScrapyCloudEx.HttpAdapter

    @impl ScrapyCloudEx.HttpAdapter
    def request(_), do: {:ok, %Response{}}

    @impl ScrapyCloudEx.HttpAdapter
    def handle_response(_response, opts), do: opts
  end

  test "opts are forwarded to HttpAdapter's handle_response/2 function" do
    request =
      RequestConfig.new()
      |> RequestConfig.put(:url, "localhost:8080/get")
      |> RequestConfig.put(:opts, foo: :bar, http_adapter: Adapter)

    opts = Helpers.make_request(request)

    assert Keyword.get(opts, :foo) == :bar
  end
end
