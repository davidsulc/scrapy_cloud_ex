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

  defp assert_no_error(%QueryParams{} = params), do: assert %QueryParams{error: nil} = params

  defp assert_invalid_param(%QueryParams{} = params, [{k, v} | []]) do
    assert %QueryParams{error: {:invalid_param, {^k, {^v, _}}}} = params
  end

  defp assert_invalid_param(%QueryParams{} = params, param) do
    assert %QueryParams{error: {:invalid_param, {^param, _}}} = params
  end


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

  describe "from_keywords/1 validations:" do
    test "format" do
      [:json, :jl, :xml, :text, :html]
      |> Enum.each(fn format ->
        QueryParams.from_keywords(format: format) |> assert_no_error()
      end)

      QueryParams.from_keywords(format: :csv, csv: [fields: ["field"]]) |> assert_no_error()

      %{error: error} = QueryParams.from_keywords(format: :foo)
      assert {:invalid_param, {:format, _}} = error
    end

    test "CSV params" do
      csv_params = [
        fields: ~w(field_a field_b),
        include_headers: 1,
        sep: ", ",
        quote: "\"",
        escape: "@",
        lineend: "\n"
      ]

      QueryParams.from_keywords(format: :csv, csv: csv_params) |> assert_no_error()

      %{error: error} = QueryParams.from_keywords(format: :csv, csv: [{:foo, :bar} | csv_params])
      assert {:invalid_param, {:csv_param, {:foo, _}}} = error

      %{error: error} = QueryParams.from_keywords(format: :csv, csv: [])
      assert {:invalid_param, {:csv_param, message}} = error
      assert message =~ "required attribute 'fields' not provided"
    end

    test "meta" do
      meta = [:_ts, :_key]
      QueryParams.from_keywords(meta: meta) |> assert_no_error()

      QueryParams.from_keywords(meta: [{:foo, :bar} | meta]) |> assert_invalid_param(:meta)
      QueryParams.from_keywords(meta: :_key) |> assert_invalid_param(:meta)
    end

    test "nodata" do
      QueryParams.from_keywords(nodata: 0) |> assert_no_error()
      QueryParams.from_keywords(nodata: 1) |> assert_no_error()

      QueryParams.from_keywords(nodata: 2) |> assert_invalid_param(:nodata)
      QueryParams.from_keywords(nodata: :foo) |> assert_invalid_param(:nodata)
    end
  end


      assert QueryParams.from_keywords(nodata: 2) |> invalid_param?(:nodata)
      assert QueryParams.from_keywords(nodata: :foo) |> invalid_param?(:nodata)
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
