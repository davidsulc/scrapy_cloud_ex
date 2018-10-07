defmodule ScrapyCloudEx.Endpoints.Storage.RequestsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ScrapyCloudEx.Endpoints.Storage.Requests

  @api_key "API_KEY"
  @params [pagination: [count: 3]]

  setup_all do
    opts = [http_adapter: Test.Support.HttpAdapters.Passthrough, decoder: & &1]
    [opts: opts]
  end

  describe "get/4" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Requests.get(@api_key, "123", @params, opts)
      assert String.starts_with?(url, "https://storage.scrapinghub.com/requests")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Requests.get(@api_key, "123", @params, opts)
    end

    test "makes a GET request", %{opts: opts} do
      assert %{method: :get} = Requests.get(@api_key, "123", @params, opts)
    end

    test "puts the id in the URL", %{opts: opts} do
      id = "123"
      %{url: url} = Requests.get(@api_key, id, @params, opts)
      assert String.contains?(url, id)
    end

    test "warns if no pagination params are given", %{opts: opts} do
      contains_warning? = fn log ->
        warning_message = ~r".*\[warn\]\s+Elixir.ScrapyCloudEx.Endpoints.Storage.Requests.get/4 called without pagination params or index.*"
        String.match?(log, warning_message)
      end

      assert capture_log(fn -> Requests.get(@api_key, "123", [], opts) end) |> contains_warning?.()

      pagination_possibilities = [
        [pagination: [count: 3]],
        [pagination: [start: "1/2/3"]],
        [pagination: [startafter: "1/2/3"]],
        [index: 3]
      ]

      for params <- pagination_possibilities do
        refute capture_log(fn -> Requests.get(@api_key, "123", params, opts) end) |> contains_warning?.()
      end

      refute capture_log(fn -> Requests.get(@api_key, "1/2/3/4", [], opts) end) |> contains_warning?.()
    end

    test "accepts a format param", %{opts: opts} do
      decoder_format = fn %{opts: opts} -> Keyword.get(opts, :decoder_format) end

      for format <- [:json, :jl, :xml, :text] do
        request = Requests.get(@api_key, "123", [format: format] ++ @params, opts)
        refute match? {:error, _}, request
        assert decoder_format.(request) == format
      end

      csv_format_params = [format: :csv, csv: [fields: [:field_one, :field_two]]]
      request = Requests.get(@api_key, "123", csv_format_params ++ @params, opts)
      refute match? {:error, _}, request
      assert decoder_format.(request) == :csv

      assert {:error, _} = Requests.get(@api_key, "123", [format: :foo] ++ @params, opts)
    end

    test "rejects invalid formats", %{opts: opts} do
      error = Requests.get(@api_key, "123", [format: :test] ++ @params, opts)
      assert {:error, {:invalid_param, {:format, _}}} = error
    end

    test "accepts a meta param", %{opts: opts} do
      request = Requests.get(@api_key, "123", [meta: [:_key, :_ts]] ++ @params, opts)
      refute match? {:error, _}, request
    end

    test "rejects invalid params", %{opts: opts} do
      error = Requests.get(@api_key, "123", [foo: :bar] ++ @params, opts)
      assert {:error, {:invalid_param, {:foo, _}}} = error
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Requests.get(@api_key, "123", @params, given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end

  describe "stats/3" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Requests.stats(@api_key, "1/2/3", opts)
      assert url == "https://storage.scrapinghub.com/requests/1/2/3/stats"
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Requests.stats(@api_key, "1/2/3", opts)
    end

    test "makes a GET request", %{opts: opts} do
      assert %{method: :get} = Requests.stats(@api_key, "1/2/3", opts)
    end

    test "puts the id in the URL", %{opts: opts} do
      id = "1/2/3"
      %{url: url} = Requests.stats(@api_key, id, opts)
      assert String.contains?(url, id)
    end

    test "requires a composite id with 3 sections", %{opts: opts} do
      assert {:error, {:invalid_param, {:id, _}}} = Requests.stats(@api_key, "1", opts)
      assert {:error, {:invalid_param, {:id, _}}} = Requests.stats(@api_key, "1/2", opts)

      refute match? {:error, _}, Requests.stats(@api_key, "1/2/3", opts)
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Requests.stats(@api_key, "1/2/3", given_opts)
      merged_opts = Keyword.merge(opts, given_opts)
      assert Keyword.equal?(merged_opts, opts)
    end
  end
end
