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

  describe "from_keywords/1" do
    test "creates a QueryParams struct from a keyword list" do
      assert %QueryParams{} = QueryParams.from_keywords(@full_params)
    end

    test "sanitizes params" do
      params = [
        format: :csv,
        csv: [
          fields: ["field_1", "field_2"],
          include_headers: true,
          line_end: "\n"
        ],
        pagination: [
          count: 3,
          start_after: "1/2/3/4"
        ],
        no_data: true
      ]

      log = capture_log(fn ->
        qp =
          params
          |> QueryParams.from_keywords()
          |> Map.from_struct()

        assert Map.get(qp, :nodata) == 1
        assert get_in(qp, [:csv, :lineend]) == "\n"
        assert get_in(qp, [:csv, :include_headers]) == 1
        assert get_in(qp, [:pagination, :startafter]) == "1/2/3/4"
      end)
      
      assert String.match?(log, ~r/replacing '.*' parameter with/)
    end

    test "wraps scoped params within a keyword list" do
      params = [
        format: :csv,
        fields: ["field_1", "field_2"],
        count: 3,
      ]

      log = capture_log(fn ->
        qp =
          params
          |> QueryParams.from_keywords()
          |> Map.from_struct()

        assert get_in(qp, [:csv, :fields]) == ["field_1", "field_2"]
        assert get_in(qp, [:pagination, :count]) == 3
      end)
      
      assert String.match?(log, ~r/values .* should be provided within the .* parameter/)
    end

    test "warns if the format is inconsistent" do
      assert capture_log(fn ->
        QueryParams.from_keywords([format: :json, csv: [fields: ["field_1", "field_2"]]])
      end) =~ "CSV parameters provided, but requested format is"

      assert capture_log(fn ->
        QueryParams.from_keywords([format: nil, csv: [fields: ["field_1", "field_2"]]])
      end) =~ "Setting `format` to :csv since `:csv` parameters were provided"
    end

    test "sets the format to json is none is given" do
      assert %{format: :json} = QueryParams.from_keywords([])
    end
  end

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
