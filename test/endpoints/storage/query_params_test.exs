defmodule ScrapyCloudEx.Endpoints.Storage.QueryParamsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ScrapyCloudEx.Endpoints.Storage.QueryParams

  @full_params [
    format: :csv,
    csv: [
      fields: ["field_1", "field_2"],
      include_headers: 1,
      sep: ", ",
      quote: "\"",
      escape: "@",
      lineend: "\n"
    ],
    pagination: [
      count: 3,
      start: "1/2/3/4"
    ],
    meta: [:_ts, :_key],
    nodata: 1
  ]

  describe "warn_if_no_pagination/2" do
    test "returns the original QueryParams struct when pagination params present" do
      params = QueryParams.from_keywords([format: :xml, pagination: [count: 3]])

      assert QueryParams.warn_if_no_pagination(params, "") == params
    end

    test "warns and returns the original QueryParams struct if no pagination" do
      params = QueryParams.from_keywords([format: :xml])

      assert capture_log(fn ->
        assert QueryParams.warn_if_no_pagination(params, "foo/1") == params
      end) =~ "foo/1 called without pagination params or index"
    end
  end

  describe "to_query/1" do
    test "encodes the QueryParams object as a query string" do
      params =
        @full_params
        |> QueryParams.from_keywords()
        |> QueryParams.to_query()
        |> URI.query_decoder()
        |> Enum.map(fn {k, v} -> {:"#{k}", v} end)

      expected_results =
        [
          {:fields, "field_1,field_2"},
          {:include_headers, "1"},
          {:sep, ", "},
          {:quote, "\""},
          {:escape, "@"},
          {:lineend, "\n"},
          {:format, "csv"},
          {:meta, "_ts"},
          {:meta, "_key"},
          {:nodata, "1"},
          {:count, "3"},
          {:start, "1/2/3/4"}
        ]

      expected_results
      |> Keyword.keys()
      |> Enum.each(fn key ->
        assert Keyword.get_values(params, key) == Keyword.get_values(expected_results, key)
      end)
    end

    test "returns an error if the QueryParams struct contains one" do
      assert {:error, :some_error} = %QueryParams{error: :some_error} |> QueryParams.to_query()
    end
  end
end
