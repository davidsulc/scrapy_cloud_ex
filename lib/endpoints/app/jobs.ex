defmodule ScrapyCloudEx.Endpoints.App.Jobs do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.{App, Helpers}
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://app.scrapinghub.com/api"
  @valid_states ~w(pending running finished deleted)

  def run(api_key, project_id, spider_name, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_binary(spider_name)
      when is_list(params)
      when is_list(opts) do
    job_settings = params |> Keyword.get(:job_settings)
    json_encoder = opts |> get_encoder()

    with {:ok, job_settings} <- format_job_settings(job_settings, json_encoder) do
      body =
        params
        |> Keyword.put(:project, project_id)
        |> Keyword.put(:spider, spider_name)
        |> maybe_add_job_settings(job_settings)

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:method, :post)
      |> RequestConfig.put(:body, body)
      |> RequestConfig.merge_opts(opts)
      |> RequestConfig.put(:url, "#{@base_url}/run.json")
      |> Helpers.make_request()
    else
      error -> {:error, error}
    end
  end

  def list(api_key, project_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_list(params)
      when is_list(opts) do
    with valid_params = [
           :format | [:job, :spider, :state, :has_tag, :lacks_tag] ++ App.pagination_params()
         ],
         :ok <- Helpers.validate_params(params, valid_params),
         true <- Keyword.get(params, :format) in [nil, :json, :jl],
         format = Keyword.get(params, :format, :json),
         :ok <- params |> Keyword.get(:state) |> validate_state() do
      params = params |> Keyword.delete(:format)
      query = [{:project, project_id} | params] |> URI.encode_query()

      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.merge_opts(opts)
      |> RequestConfig.put(:url, "#{@base_url}/jobs/list.#{format}?#{query}")
      |> Helpers.make_request()
    else
      false ->
        error =
          "expected format to be one of :json, :jl, but got `#{Keyword.get(params, :format)}`"
          |> Helpers.invalid_param_error(:format)

        {:error, error}

      {:invalid_param, _} = error ->
        {:error, error}
    end
  end

  def update(api_key, project_id, job_or_jobs, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(params)
      when is_list(opts) do
    with :ok <- Helpers.validate_params(params, [:add_tag, :remove_tag]) do
      request = prepare_basic_post_request(api_key, project_id, job_or_jobs, opts)

      request
      |> RequestConfig.put(:url, "#{@base_url}/jobs/update.json")
      |> RequestConfig.put(:body, request.body ++ params)
      |> Helpers.make_request()
    else
      {:invalid_param, _} = error -> {:error, error}
    end
  end

  def delete(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    prepare_basic_post_request(api_key, project_id, job_or_jobs, opts)
    |> RequestConfig.put(:url, "#{@base_url}/jobs/delete.json")
    |> Helpers.make_request()
  end

  def stop(api_key, project_id, job_or_jobs, opts \\ [])
      when is_api_key(api_key)
      when is_id(project_id)
      when is_id(job_or_jobs) or is_list(job_or_jobs)
      when is_list(opts) do
    prepare_basic_post_request(api_key, project_id, job_or_jobs, opts)
    |> RequestConfig.put(:url, "#{@base_url}/jobs/stop.json")
    |> Helpers.make_request()
  end

  defp prepare_basic_post_request(api_key, project_id, job_or_jobs, opts) do
    body =
      job_or_jobs
      |> format_jobs()
      |> Keyword.put(:project, project_id)

    RequestConfig.new()
    |> RequestConfig.put(:api_key, api_key)
    |> RequestConfig.put(:method, :post)
    |> RequestConfig.put(:body, body)
    |> RequestConfig.merge_opts(opts)
  end

  defp format_jobs(job_or_jobs) do
    job_or_jobs
    |> List.wrap()
    |> Enum.map(&{:job, &1})
  end

  defp get_encoder(opts) do
    opts
    |> Keyword.get(:encoder)
    |> case do
      nil -> get_default_encoder(opts)
      encoder -> encoder
    end
  end

  defp get_default_encoder(opts) do
    with true <- Keyword.get(opts, :encoder_fallback, true),
         true <- function_exported?(Jason, :encode, 2) do
      &Jason.encode(&1, [])
    else
      _ -> nil
    end
  end

  defp format_job_settings(nil, _encoder), do: {:ok, []}

  defp format_job_settings(settings, _encoder) when is_binary(settings), do: {:ok, settings}

  defp format_job_settings(settings, _encoder = nil) when is_map(settings) do
    "job_settings must be provided as a string-encoded JSON object, or a JSON encoder must be provided as an option (falling back to Jason unsuccessful)"
    |> Helpers.invalid_param_error(:job_settings)
  end

  # TODO: document that encoder must return {:ok, encoded_json} on success
  defp format_job_settings(settings, encoder) when is_map(settings), do: encoder.(settings)

  defp format_job_settings(_settings, _encoder) do
    "expected job_settings to be a string-encoded JSON object or a map"
    |> Helpers.invalid_param_error(:job_settings)
  end

  defp maybe_add_job_settings(list, []), do: list

  defp maybe_add_job_settings(list, settings) do
    list |> Keyword.put(:job_settings, settings)
  end

  defp validate_state(nil), do: :ok
  defp validate_state(state) when state in @valid_states, do: :ok

  defp validate_state(state),
    do:
      "state '#{state}' not among valid states: #{@valid_states |> Enum.join(", ")}"
      |> Helpers.invalid_param_error(:state)
end
