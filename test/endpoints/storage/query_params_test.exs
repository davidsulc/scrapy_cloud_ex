defmodule ScrapyCloudEx.Endpoints.Storage.QueryParamsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ScrapyCloudEx.Endpoints.Storage.QueryParams

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
end
