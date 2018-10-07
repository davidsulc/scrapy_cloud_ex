defmodule ScrapyCloudEx.Endpoints.App.CommentsTest do
  use ExUnit.Case, async: true

  @api_key "API_KEY"

  alias ScrapyCloudEx.Endpoints.App.Comments

  defmodule TestHttpAdapter do
    @behaviour ScrapyCloudEx.HttpAdapter

    @impl ScrapyCloudEx.HttpAdapter
    def request(request_config), do: request_config
  end

  setup_all do
    opts = [http_adapter: TestHttpAdapter, decoder: & &1]
    [opts: opts]
  end

  describe "get/3" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Comments.get(@api_key, "1/2/3", opts)
      assert String.starts_with?(url, "https://app.scrapinghub.com/api/comments")
    end
  end
end
