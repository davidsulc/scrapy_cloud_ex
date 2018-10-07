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

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Comments.get(@api_key, "1/2/3", opts)
    end

    test "makes a GET request", %{opts: opts} do
      assert %{method: :get} = Comments.get(@api_key, "1/2/3", opts)
    end

    test "puts the composite id in the URL", %{opts: opts} do
      for id <- ["1/2/3", "1/2/3/4", "1/2/3/4/field_name"] do
        %{url: url} = Comments.get(@api_key, id, opts)
        assert String.contains?(url, id)
      end
    end

    test "requires a composite id with at least 3 sections", %{opts: opts} do
      assert {:error, {:invalid_param, {:id, _}}} = Comments.get(@api_key, "1", opts)
      assert {:error, {:invalid_param, {:id, _}}} = Comments.get(@api_key, "1/2", opts)

      refute match? {:error, _}, Comments.get(@api_key, "1/2/3", opts)
      refute match? {:error, _}, Comments.get(@api_key, "1/2/3/4", opts)
      refute match? {:error, _}, Comments.get(@api_key, "1/2/3/4/field_name", opts)
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Comments.get(@api_key, "1/2/3", given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end
end
