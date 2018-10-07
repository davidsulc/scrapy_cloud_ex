defmodule ScrapyCloudEx.Endpoints.App.CommentsTest do
  use ExUnit.Case, async: true

  @api_key "API_KEY"

  alias ScrapyCloudEx.Endpoints.App.Comments

  setup_all do
    opts = [http_adapter: Test.Support.HttpAdapters.Passthrough, decoder: & &1]
    [opts: opts]
  end

  describe "get/3" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Comments.get(@api_key, "1/2/3", opts)
      assert String.starts_with?(url, "https://app.scrapinghub.com/api/comments")
    end
  end
end
