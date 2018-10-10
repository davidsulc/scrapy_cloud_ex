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
    test ":api_key only accepts a string", %{config: config} do
      assert_raise ArgumentError, ~r/value for key 'api_key' must be a string/, fn ->
        config |> RC.put(:api_key, :foo)
      end
      assert %RC{} = RC.put(config, :api_key, "123asd")
    end

    test ":url only accepts a string", %{config: config} do
      assert_raise ArgumentError, ~r/value for key 'url' must be a string/, fn ->
        config |> RC.put(:url, :foo)
      end
      assert %RC{} = RC.put(config, :url, "www.example.com")
    end

    test ":method only accepts an atom corresponding to http verbs", %{config: config} do
      for method <- [:foo, "foo"] do
        assert_raise ArgumentError, ~r/method must be one of/, fn ->
          config |> RC.put(:method, method)
        end
      end

      for method <- [:get, :post, :put, :delete] do
        assert %RC{} = RC.put(config, :method, method)
      end
    end

    test ":headers only accepts a list of tuples", %{config: config} do
      assert_raise ArgumentError, ~r/must be a list of tuples/, fn ->
        config |> RC.put(:headers, %{a: :b, foo: :bar})
      end

      assert %RC{} = RC.put(config, :headers, [a: :b, foo: :bar])
      assert %RC{} = RC.put(config, :headers, [{"a", "b"}, {"foo", "bar"}])
    end

    test ":body only accepts a list of tuples", %{config: config} do
      assert_raise ArgumentError, ~r/must be a list of tuples/, fn ->
        config |> RC.put(:body, %{a: :b, foo: :bar})
      end

      assert %RC{} = RC.put(config, :body, [a: :b, foo: :bar])
      assert %RC{} = RC.put(config, :body, [{"a", "b"}, {"foo", "bar"}])
    end

    test "raises if trying to overwrite :opts", %{config: config} do
      assert_raise ArgumentError, ~r/merge_opts\/2 to add options$/, fn ->
        config |> RC.put(:opts, foo: :bar)
      end
    end

    test "raises for keys that aren't in the RequestConfig struct", %{config: config} do
      assert_raise ArgumentError, ~r/key must be one of/, fn ->
        config |> RC.put(:foo, :bar)
      end
    end
  end
end
