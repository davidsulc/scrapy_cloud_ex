defmodule ScrapyCloudEx.Endpoints.App.JobsTest do
  use ExUnit.Case, async: true

  @api_key "API_KEY"
  @project_id "PROJECT_ID"
  @spider_name "SPIDER_NAME"

  alias ScrapyCloudEx.Endpoints.App.Jobs

  defmodule TestHttpAdapter do
    @behaviour ScrapyCloudEx.HttpAdapter

    @impl ScrapyCloudEx.HttpAdapter
    def request(request_config), do: request_config
  end

  setup_all do
    opts = [http_adapter: TestHttpAdapter, decoder: & &1]
    [opts: opts]
  end

  describe "run/5" do
    test "uses the proper API endpoint", %{opts: opts} do
      %{url: url} = Jobs.run(@api_key, @project_id, @spider_name, [], opts)
      assert url |> String.starts_with?("https://app.scrapinghub.com/api/run.json")
    end

    test "contains the api key", %{opts: opts} do
      assert %{api_key: @api_key} = Jobs.run(@api_key, @project_id, @spider_name, [], opts)
    end

    test "makes a POST request", %{opts: opts} do
      assert %{method: post} = Jobs.run(@api_key, @project_id, @spider_name, [], opts)
    end

    test "puts the project id and spider name in the request body", %{opts: opts} do
      %{body: body} = Jobs.run(@api_key, @project_id, @spider_name, [], opts)
      assert Keyword.equal?(body, project: @project_id, spider: @spider_name)
    end

    test "puts the given params in the request body", %{opts: opts} do
      params = [add_tag: "foo", priority: 1, units: 3]
      %{body: body} = Jobs.run(@api_key, @project_id, @spider_name, params, opts)

      for {k, v} <- params do
        assert Keyword.get(body, k) == v
      end
    end

    # per the API 'Any other parameter will be treated as a spider argument.'
    test "also forwards arbitrary params", %{opts: opts} do
      params = [foo: :bar]
      %{body: body} = Jobs.run(@api_key, @project_id, @spider_name, params, opts)

      assert Keyword.get(body, :foo) == :bar
    end

    test "accepts job_settings as JSON string", %{opts: opts} do
      json = "{'foo': 'bar'}"
      params = [job_settings: json]
      %{body: body} = Jobs.run(@api_key, @project_id, @spider_name, params, opts)
      assert Keyword.get(body, :job_settings) == json
    end

    test "accepts job_settings as a map if JSON encoder is available", %{opts: opts} do
      json = "{'foo': 'bar'}"
      params = [job_settings: %{a: :b}]
      encoder = fn _ -> {:ok, json} end
      opts = [{:json_encoder, encoder} | opts]

      %{body: body} = Jobs.run(@api_key, @project_id, @spider_name, params, opts)

      assert Keyword.get(body, :job_settings) == json
    end

    test "returns an error if job_settings are provided without a JSON encoder", %{opts: opts} do
      params = [job_settings: %{a: :b}]
      error = Jobs.run(@api_key, @project_id, @spider_name, params, [{:json_encoder, nil} | opts])
      assert {:error, {:invalid_param, {:job_settings, _}}} = error
    end

    test "forwards the given options", %{opts: opts} do
      given_opts = [{:foo, :bar} | opts]
      %{opts: opts} = Jobs.run(@api_key, @project_id, @spider_name, [], given_opts)
      assert Keyword.equal?(given_opts, opts)
    end
  end
end
