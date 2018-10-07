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

      refute match?({:error, _}, Comments.get(@api_key, "1/2/3", opts))
      refute match?({:error, _}, Comments.get(@api_key, "1/2/3/4", opts))
      refute match?({:error, _}, Comments.get(@api_key, "1/2/3/4/field_name", opts))
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Comments.get(@api_key, "1/2/3", given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end

  describe "put/4" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Comments.put(@api_key, "1/2/3", [text: "comment text"], opts)
      assert String.starts_with?(url, "https://app.scrapinghub.com/api/comments")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Comments.put(@api_key, "1", [text: "comment text"], opts)
    end

    test "makes a PUT request", %{opts: opts} do
      assert %{method: :put} = Comments.put(@api_key, "1", [text: "comment text"], opts)
    end

    test "puts the id in the URL", %{opts: opts} do
      id = "123"
      %{url: url} = Comments.put(@api_key, id, [text: "text"], opts)
      assert String.contains?(url, id)
    end

    test "requires a `text` param", %{opts: opts} do
      request = Comments.put(@api_key, "1", [], opts)
      assert {:error, {:invalid_param, {:text, _}}} = request
    end

    test "adds the text param to the request body", %{opts: opts} do
      text = "Comment text"
      %{body: body} = Comments.put(@api_key, "1", [text: text], opts)

      assert Keyword.get(body, :text) == text
    end

    test "rejects invalid params", %{opts: opts} do
      request = Comments.put(@api_key, "1", [foo: :bar], opts)
      assert {:error, {:invalid_param, {:foo, _}}} = request
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Comments.put(@api_key, "1", [text: "text"], given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end

  describe "post/4" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Comments.post(@api_key, "1/2/3/4", [text: "text"], opts)
      assert String.starts_with?(url, "https://app.scrapinghub.com/api/comments")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Comments.post(@api_key, "1/2/3/4", [text: "text"], opts)
    end

    test "makes a POST request", %{opts: opts} do
      assert %{method: :post} = Comments.post(@api_key, "1/2/3/4", [text: "text"], opts)
    end

    test "puts the id in the URL", %{opts: opts} do
      for id <- ~w(1/2/3/4 1/2/3/4/field_name) do
        %{url: url} = Comments.post(@api_key, id, [text: "text"], opts)
        assert String.contains?(url, id)
      end
    end

    test "requires a composite id with at least 3 sections", %{opts: opts} do
      request = Comments.post(@api_key, "1", [text: "text"], opts)
      assert {:error, {:invalid_param, {:id, _}}} = request

      request = Comments.post(@api_key, "1/2", [text: "text"], opts)
      assert {:error, {:invalid_param, {:id, _}}} = request

      refute match?({:error, _}, Comments.post(@api_key, "1/2/3/4", [text: "text"], opts))

      request = Comments.post(@api_key, "1/2/3/4/field_name", [text: "text"], opts)
      refute match?({:error, _}, request)
    end

    test "requires a `text` param", %{opts: opts} do
      request = Comments.post(@api_key, "1/2/3/4", [], opts)
      assert {:error, {:invalid_param, {:text, _}}} = request
    end

    test "adds the text param to the request body", %{opts: opts} do
      text = "Comment text"
      %{body: body} = Comments.post(@api_key, "1/2/3/4", [text: text], opts)

      assert Keyword.get(body, :text) == text
    end

    test "rejects invalid params", %{opts: opts} do
      request = Comments.post(@api_key, "1/2/3/4", [foo: :bar], opts)
      assert {:error, {:invalid_param, {:foo, _}}} = request
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Comments.post(@api_key, "1/2/3/4", [text: "text"], given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end

  describe "delete/3" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Comments.delete(@api_key, "1", opts)
      assert String.starts_with?(url, "https://app.scrapinghub.com/api/comments")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Comments.delete(@api_key, "1", opts)
    end

    test "makes a DELETE request", %{opts: opts} do
      assert %{method: :delete} = Comments.delete(@api_key, "1", opts)
    end

    test "puts the id in the URL", %{opts: opts} do
      for id <- ~w(1 1/2/3/4 1/2/3/4/field_name) do
        %{url: url} = Comments.delete(@api_key, id, opts)
        assert String.contains?(url, id)
      end
    end

    test "requires a composite id with exactly 1, or more than 3 sections", %{opts: opts} do
      assert {:error, {:invalid_param, {:id, _}}} = Comments.delete(@api_key, "1/2", opts)

      refute match?({:error, _}, Comments.delete(@api_key, "1", opts))
      refute match?({:error, _}, Comments.delete(@api_key, "1/2/3/4", opts))
      refute match?({:error, _}, Comments.delete(@api_key, "1/2/3/4/field_name", opts))
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Comments.delete(@api_key, "1", given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end

  describe "stats/3" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Comments.stats(@api_key, "PROJECT", opts)
      assert url == "https://app.scrapinghub.com/api/comments/PROJECT/stats"
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Comments.stats(@api_key, "1", opts)
    end

    test "makes a GET request", %{opts: opts} do
      assert %{method: :get} = Comments.stats(@api_key, "1", opts)
    end

    test "puts the id in the URL", %{opts: opts} do
      id = "123"
      %{url: url} = Comments.stats(@api_key, id, opts)
      assert String.contains?(url, id)
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Comments.stats(@api_key, "1", given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end
end
