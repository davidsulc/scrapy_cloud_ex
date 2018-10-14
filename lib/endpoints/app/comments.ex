defmodule ScrapyCloudEx.Endpoints.App.Comments do
  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://app.scrapinghub.com/api/comments"

  @spec get(String.t, String.t, Keyword.t) :: ScrapyCloudEx.result
  def get(api_key, composite_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(opts) do
    case basic_comment_request(api_key, composite_id, [], opts, :get) do
      %RequestConfig{} = request -> request |> Helpers.make_request()
      error -> {:error, error}
    end
  end

  @spec put(String.t, String.t, Keyword.t, Keyword.t) :: ScrapyCloudEx.result
  def put(api_key, composite_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(params)
      when is_list(opts) do
    case basic_comment_request(api_key, composite_id, params, opts, :put) do
      %RequestConfig{} = request -> request |> Helpers.make_request()
      error -> {:error, error}
    end
  end

  @spec post(String.t, String.t, Keyword.t, Keyword.t) :: ScrapyCloudEx.result
  def post(api_key, composite_id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(params)
      when is_list(opts) do
    case basic_comment_request(api_key, composite_id, params, opts, :post) do
      %RequestConfig{} = request -> request |> Helpers.make_request()
      error -> {:error, error}
    end
  end

  @spec delete(String.t, String.t, Keyword.t) :: ScrapyCloudEx.result
  def delete(api_key, composite_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(opts) do
    case basic_comment_request(api_key, composite_id, [], opts, :delete) do
      %RequestConfig{} = request -> request |> Helpers.make_request()
      error -> {:error, error}
    end
  end

  @spec stats(String.t, String.t | integer, Keyword.t) :: ScrapyCloudEx.result
  def stats(api_key, project_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id)
      when is_list(opts) do
    RequestConfig.new()
    |> RequestConfig.put(:api_key, api_key)
    |> RequestConfig.merge_opts(opts)
    |> RequestConfig.put(:url, [@base_url, project_id, "stats"] |> merge_sections())
    |> Helpers.make_request()
  end

  @spec basic_comment_request(String.t, String.t, Keyword.t, Keyword.t, atom) :: RequestConfig.t | ScrapyCloudEx.tagged_error_info
  defp basic_comment_request(api_key, composite_id, params, opts, method) do
    with :ok <- Helpers.validate_params(params, [:text]),
         :ok <- check_constraints(method, composite_id, params) do
      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:method, method)
      |> RequestConfig.put(:body, params)
      |> RequestConfig.merge_opts(opts)
      |> RequestConfig.put(:url, [@base_url, composite_id] |> Enum.join("/"))
    else
      {:invalid_param, _} = error -> error
    end
  end

  @spec check_constraints(atom, String.t, Keyword.t) :: :ok | ScrapyCloudEx.tagged_error_info
  defp check_constraints(method, composite_id, params)
       when is_atom(method)
       when is_binary(composite_id) or is_integer(composite_id)
       when is_list(params) do
    do_check_constraints(method, section_count(composite_id), Keyword.has_key?(params, :text))
  end

  @spec do_check_constraints(atom, integer, boolean) :: :ok | ScrapyCloudEx.tagged_error_info

  # comments/:project_id/:spider_id/:job_id
  defp do_check_constraints(:get, 3, _), do: :ok

  # comments/:project_id/:spider_id/:job_id/:item_no[/:field]
  defp do_check_constraints(:get, count, _) when count > 3, do: :ok

  defp do_check_constraints(:get, _, _) do
    "expected `id` param to have at least 3 sections"
    |> Helpers.invalid_param_error(:id)
  end

  # comments/:comment_id
  defp do_check_constraints(:put, _, true), do: :ok

  defp do_check_constraints(:put, _, false), do: required_text_param_not_provided()

  defp do_check_constraints(:post, _count, false), do: required_text_param_not_provided()

  # comments/:project_id/:spider_id/:job_id/:item_no[/:field]
  defp do_check_constraints(:post, count, _) when count > 3, do: :ok

  defp do_check_constraints(:post, _, _) do
    "expected `id` param to have at least 4 sections"
    |> Helpers.invalid_param_error(:id)
  end

  # comments/:comment_id
  defp do_check_constraints(:delete, 1, _), do: :ok

  # comments/:project_id/:spider_id/:job_id/:item_no[/:field]
  defp do_check_constraints(:delete, count, _) when count > 3, do: :ok

  defp do_check_constraints(:delete, _, _) do
    "expected `id` param to have only 1 section, or at least 4 sections"
    |> Helpers.invalid_param_error(:id)
  end

  @spec required_text_param_not_provided() :: ScrapyCloudEx.tagged_error_info
  defp required_text_param_not_provided() do
    "required `text` param not provided" |> Helpers.invalid_param_error(:text)
  end

  @spec merge_sections([String.t]) :: String.t
  defp merge_sections(sections), do: sections |> Enum.join("/")

  @spec section_count(String.t) :: integer

  defp section_count(composite) when is_integer(composite), do: 1

  defp section_count(composite) when is_binary(composite),
    do: composite |> String.split("/") |> length()
end
