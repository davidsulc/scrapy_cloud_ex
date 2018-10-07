defmodule ScrapyCloudEx.Endpoints.Storage.JobQTest do
  use ExUnit.Case, async: true

  @api_key "API_KEY"

  alias ScrapyCloudEx.Endpoints.Storage.JobQ
  alias Test.Support.URI

  setup_all do
    opts = [http_adapter: Test.Support.HttpAdapters.Passthrough, decoder: & &1]
    [opts: opts]
  end

  describe "count/4" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = JobQ.count(@api_key, "1", [], opts)
      assert String.starts_with?(url, "https://storage.scrapinghub.com/jobq/1/count")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = JobQ.count(@api_key, "123", [], opts)
    end

    test "makes a GET request", %{opts: opts} do
      assert %{method: :get} = JobQ.count(@api_key, "123", [], opts)
    end

    test "rejects invalid params", %{opts: opts} do
      error = JobQ.count(@api_key, "123", [foo: :bar], opts)
      assert {:error, {:invalid_param, {:foo, _}}} = error
    end

    test "puts params in the query string", %{opts: opts} do
      params = [
        spider: "spidey",
        state: "finished",
        startts: "1397762393489",
        endts: "1397762399000",
        has_tag: "tag_a",
        has_tag: "tag_b",
        lacks_tag: "tag_x",
        lacks_tag: "tag_y"
      ]

      %{url: url} = JobQ.count(@api_key, "1", params, opts)
      query_map = url |> URI.get_query()

      for key <- params |> Keyword.keys() do
        given_values = Keyword.get_values(params, key)
        query_values = Map.get(query_map, "#{key}") |> List.wrap()
        assert given_values -- query_values == []
        assert query_values -- given_values == []
      end
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = JobQ.count(@api_key, "123", [], given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end

  describe "list/4" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = JobQ.list(@api_key, "1", [], opts)
      assert String.starts_with?(url, "https://storage.scrapinghub.com/jobq/1/list")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = JobQ.list(@api_key, "123", [], opts)
    end

    test "makes a GET request", %{opts: opts} do
      assert %{method: :get} = JobQ.list(@api_key, "123", [], opts)
    end

    test "rejects invalid params", %{opts: opts} do
      error = JobQ.list(@api_key, "123", [foo: :bar], opts)
      assert {:error, {:invalid_param, {:foo, _}}} = error
    end

    test "accepts json and jl formats", %{opts: opts} do
      for format <- [:json, :jl] do
        %{opts: opts} = JobQ.list(@api_key, "123", [format: format], opts)
        assert Keyword.get(opts, :decoder_format) == format
      end
    end

    test "puts params in the query string", %{opts: opts} do
      params = [
        spider: "spidey",
        state: "finished",
        startts: "1397762393489",
        endts: "1397762399000",
        count: "3",
        start: "5",
        stop: "1/2/3",
        key: "5/6/7",
        key: "7/8/9",
        key: "9/10/11",
        has_tag: "tag_a",
        has_tag: "tag_b",
        lacks_tag: "tag_x",
        lacks_tag: "tag_y"
      ]

      %{url: url} = JobQ.list(@api_key, "1", params, opts)
      query_map = url |> URI.get_query()

      for key <- params |> Keyword.keys() do
        given_values = Keyword.get_values(params, key)
        query_values = Map.get(query_map, "#{key}") |> List.wrap()
        assert given_values -- query_values == []
        assert query_values -- given_values == []
      end
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = JobQ.list(@api_key, "123", [], given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end
end
