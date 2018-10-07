defmodule ScrapyCloudEx.Endpoints.Storage.ItemsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  @api_key "API_KEY"
  @params [pagination: [count: 3]]

  alias ScrapyCloudEx.Endpoints.Storage.Items
  # alias Test.Support.URI

  setup_all do
    opts = [http_adapter: Test.Support.HttpAdapters.Passthrough, decoder: & &1]
    [opts: opts]
  end

  describe "get/4" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Items.get(@api_key, "123", @params, opts)
      assert String.starts_with?(url, "https://storage.scrapinghub.com/items")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Items.get(@api_key, "123", @params, opts)
    end

    test "makes a GET request", %{opts: opts} do
      assert %{method: :get} = Items.get(@api_key, "123", @params, opts)
    end

    test "puts the id in the URL", %{opts: opts} do
      id = "123"
      %{url: url} = Items.get(@api_key, id, @params, opts)
      assert String.contains?(url, id)
    end

    test "warns if no pagination params are given", %{opts: opts} do
      contains_warning? = fn log ->
        warning_message = ~r".*\[warn\]\s+Elixir.ScrapyCloudEx.Endpoints.Storage.Items.get/4 called without pagination params or index.*"
        String.match?(log, warning_message)
      end

      assert capture_log(fn -> Items.get(@api_key, "123", [], opts) end) |> contains_warning?.()
      assert capture_log(fn -> Items.get(@api_key, "1/2/3/field_name", [], opts) end) |> contains_warning?.()

      pagination_possibilities = [
        [pagination: [count: 3]],
        [pagination: [start: "1/2/3"]],
        [pagination: [startafter: "1/2/3"]],
        [index: 3]
      ]

      for params <- pagination_possibilities do
        refute capture_log(fn -> Items.get(@api_key, "123", params, opts) end) |> contains_warning?.()
      end

      refute capture_log(fn -> Items.get(@api_key, "1/2/3/4", [], opts) end) |> contains_warning?.()
    end

    test "accepts a format param", %{opts: opts} do
      for format <- [:json, :jl, :xml, :text] do
        request = Items.get(@api_key, "123", [format: format] ++ @params, opts)
        refute match? {:error, _}, request
      end

      csv_format_params = [format: :csv, csv: [fields: [:field_one, :field_two]]]
      request = Items.get(@api_key, "123", csv_format_params ++ @params, opts)
      refute match? {:error, _}, request

      assert {:error, _} = Items.get(@api_key, "123", [format: :foo] ++ @params, opts)
    end

    test "rejects invalid params", %{opts: opts} do
      error = Items.get(@api_key, "123", [foo: :bar] ++ @params, opts)
      assert {:error, {:invalid_param, {:foo, _}}} = error
    end

    test "rejects invalid formats", %{opts: opts} do
      error = Items.get(@api_key, "123", [format: :test] ++ @params, opts)
      assert {:error, {:invalid_param, {:format, _}}} = error
    end
  end
end
