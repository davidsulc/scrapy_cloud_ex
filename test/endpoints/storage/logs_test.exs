defmodule ScrapyCloudEx.Endpoints.Storage.LogsTest do
  use ExUnit.Case, async: true

  @api_key "API_KEY"
  @id "1/2/3"

  alias ScrapyCloudEx.Endpoints.Storage.Logs
  alias Test.Support.URI

  setup_all do
    opts = [http_adapter: Test.Support.HttpAdapters.Passthrough, decoder: & &1]
    [opts: opts]
  end

  describe "get/4" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Logs.get(@api_key, @id, [], opts)
      assert String.starts_with?(url, "https://storage.scrapinghub.com/logs/#{@id}")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Logs.get(@api_key, @id, [], opts)
    end

    test "makes a GET request", %{opts: opts} do
      assert %{method: :get} = Logs.get(@api_key, @id, [], opts)
    end

    test "rejects invalid params", %{opts: opts} do
      error = Logs.get(@api_key, @id, [foo: :bar], opts)
      assert {:error, {:invalid_param, {:foo, _}}} = error
    end

    test "puts params in the query string", %{opts: opts} do
      params = [
        format: :xml,
        pagination: [count: 3, start: "5/6/7/8"],
        meta: [:_key, :_ts]
      ]

      %{url: url} = Logs.get(@api_key, @id, params, opts)

      query_string = url |> URI.get_query()
      assert URI.equivalent?(query_string, params)
    end

    test "accepts json, jl, xml, and csv formats", %{opts: opts} do
      for format <- [:json, :jl, :xml] do
        %{opts: opts} = Logs.get(@api_key, @id, [format: format], opts)
        assert Keyword.get(opts, :decoder_format) == format
      end

      %{opts: opts} =
        Logs.get(@api_key, @id, [format: :csv, csv: [fields: ~w(level message)]], opts)

      assert Keyword.get(opts, :decoder_format) == :csv
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Logs.get(@api_key, @id, [], given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end
end
