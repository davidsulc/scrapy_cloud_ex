defmodule ScrapyCloudEx.Endpoints.Storage.ActivityTest do
  use ExUnit.Case, async: true

  @api_key "API_KEY"

  alias ScrapyCloudEx.Endpoints.Storage.Activity
  alias Test.Support.URI

  setup_all do
    opts = [http_adapter: Test.Support.HttpAdapters.Passthrough, decoder: & &1]
    [opts: opts]
  end

  describe "list/4" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Activity.list(@api_key, "1", [], opts)
      assert String.starts_with?(url, "https://storage.scrapinghub.com/activity/1")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Activity.list(@api_key, "123", [], opts)
    end

    test "makes a GET request", %{opts: opts} do
      assert %{method: :get} = Activity.list(@api_key, "123", [], opts)
    end

    test "rejects invalid params", %{opts: opts} do
      error = Activity.list(@api_key, "123", [foo: :bar], opts)
      assert {:error, {:invalid_param, {:foo, _}}} = error
    end

    test "puts params in the query string", %{opts: opts} do
      params = [
        count: 3,
        format: :xml
      ]

      %{url: url} = Activity.list(@api_key, "1", params, opts)
      query_map = url |> URI.get_query()

      for key <- params |> Keyword.keys() do
        given_values = Keyword.get_values(params, key) |> Enum.map(&"#{&1}")
        query_values = Map.get(query_map, "#{key}") |> List.wrap()
        assert given_values -- query_values == []
        assert query_values -- given_values == []
      end
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Activity.list(@api_key, "123", [], given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end
end
