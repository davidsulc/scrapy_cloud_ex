defmodule ScrapyCloudEx.EndpointsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ScrapyCloudEx.Endpoints

  test "scope_params/3" do
    log =
      capture_log(fn ->
        params = Endpoints.scope_params([foo: :bar, a: :a, letters: [b: :b]], :letters, [:a, :b])
        assert Keyword.equal?(params, foo: :bar, letters: [a: :a, b: :b])
      end)

    assert log =~ "values `[a: :a]` should be provided within the `letters` parameter"

    assert capture_log(fn ->
             Endpoints.scope_params([foo: :bar, letters: [a: :a, b: :b]], :letters, [:a, :b])
           end) =~ ""
  end

  test "merge_scope/2" do
    params = Endpoints.merge_scope([other: [foo: :bar], letters: [a: :a, b: :b]], :letters)
    assert Keyword.equal?(params, other: [foo: :bar], a: :a, b: :b)
  end
end
