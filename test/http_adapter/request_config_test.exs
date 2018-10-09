defmodule ScrapyCloudEx.HttpAdapter.RequestConfigTest do
  use ExUnit.Case

  alias ScrapyCloudEx.HttpAdapter.RequestConfig, as: RC

  defp has_default_opts?(%RC{opts: opts}) do
    Keyword.get(opts, :decoder) != nil && Keyword.get(opts, :decoder_format) != nil
  end

  setup_all do
    [config: RC.new()]
  end

  test "has GET method by default", %{config: config} do
    assert %{method: :get} = config
  end

  test "has default decoder and decoder_format options", %{config: config} do
    assert has_default_opts?(config)
  end

  describe "merge_opts/2" do
    test "merging in new values won't remove defaults", %{config: config} do
      config = config |> RC.merge_opts(foo: :bar)
      assert has_default_opts?(config)
    end

    test "merging in new values can replace defaults", %{config: config} do
      config = config |> RC.merge_opts(decoder_format: :foo)
      assert has_default_opts?(config)

      %{opts: opts} = config
      assert Keyword.get(opts, :decoder_format) == :foo
    end
  end

  describe "put/3" do
    test "raises if trying to overwrite :opts", %{config: config} do
      assert_raise ArgumentError, ~r/merge_opts\/2 to add options$/, fn ->
        config |> RC.put(:opts, foo: :bar)
      end
    end

    test "behaves like Map.put/3 for keys that aren't :opts", %{config: config} do
      config = config |> RC.put(:url, "www.example.com")
      assert Map.get(config, :url) == "www.example.com"
    end
  end
end
