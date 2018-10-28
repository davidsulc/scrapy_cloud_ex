defmodule ScrapyCloudEx.Endpoints.App.Comments do
  @moduledoc """
  Wraps the [comments](https://doc.scrapinghub.com/api/comments.html) endpoint.

  When functions return comment data, each comment will be formatted as a map with the following key-value pairs ([docs](https://doc.scrapinghub.com/api/comments.html#comment-object)):

    * `id` - the comment id
    * `text` - the comment text
    * `created` - the created date
    * `archived` - the archived date (or `nil` if not archived)
    * `author` - the comment author
    * `avatar` - the gravatar URL for the author
    * `editable` - a boolean value indicating whether the comment can be edited
  """

  import ScrapyCloudEx.Endpoints.Guards

  alias ScrapyCloudEx.Endpoints.Helpers
  alias ScrapyCloudEx.HttpAdapter.RequestConfig

  @base_url "https://app.scrapinghub.com/api/comments"

  @doc """
  Retrieves comments for a job, optionally indexed by item or item/field.

  The `composite_id` must have at least 3 sections (i.e. refer to a job).
  When using an id with 4 sections (i.e. refering to an item), the comments
  for fields within that item will also be returned.

  The return values will be a map whose keys are strings indicating the item index/field identifier
  (e.g. `"11"`, `"11/logo"`).

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs [here](https://doc.scrapinghub.com/api/comments.html#comments-project-id-spider-id-job-id) and [here](https://doc.scrapinghub.com/api/comments.html#comments-project-id-spider-id-job-id-item-no-field) (GET method).

  ## Example

  ```
  # Retrieve all comments for project 14, spider 13, job 12
  ScrapyCloudEx.Endpoints.App.Comments.get("API_KEY", "14/13/12")

  # Retrieve comments for item at index 11 (including comments on its fields)
  # for project 14, spider 13, job 12
  ScrapyCloudEx.Endpoints.App.Comments.get("API_KEY", "14/13/12/11")

  # As above, but retrieve only comment for field "logo"
  ScrapyCloudEx.Endpoints.App.Comments.get("API_KEY", "14/13/12/11/logo")
  ```
  """
  @spec get(String.t(), String.t(), Keyword.t()) :: ScrapyCloudEx.result()
  def get(api_key, composite_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(composite_id) and composite_id != ""
      when is_list(opts) do
    case basic_comment_request(api_key, composite_id, [], opts, :get) do
      %RequestConfig{} = request -> request |> Helpers.make_request()
      error -> {:error, error}
    end
  end

  @doc """
  Updates a single comment by id.

  The id is a numerical id, as returned e.g. by `get/3` or `post/4` and NOT a binary
  index/field identifier (such as `"11/logo"`).

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See [docs](https://doc.scrapinghub.com/api/comments.html#comments-comment-id) (PUT method).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.App.Comments.put("API_KEY", 123456, text: "foo bar")
  ```
  """
  @spec put(String.t(), String.t(), Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result()
  def put(api_key, id, params \\ [], opts \\ [])
      when is_api_key(api_key)
      when is_binary(id) and id != ""
      when is_list(params)
      when is_list(opts) do
    case basic_comment_request(api_key, id, params, opts, :put) do
      %RequestConfig{} = request -> request |> Helpers.make_request()
      error -> {:error, error}
    end
  end

  @doc """
  Creates a single comment.

  The `composite_id` must have at least 4 sections (i.e. refer to an item).

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See [docs](https://doc.scrapinghub.com/api/comments.html#comments-project-id-spider-id-job-id-item-no-field) (POST method).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.App.Comments.post("API_KEY", "14/13/12/11", text: "some text")
  ScrapyCloudEx.Endpoints.App.Comments.post("API_KEY", "14/13/12/11/logo", text: "some text")
  ```
  """
  @spec post(String.t(), String.t(), Keyword.t(), Keyword.t()) :: ScrapyCloudEx.result()
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

  @doc """
  Archives a single comment.

  The `id` must be a comment id, or have at least 4 sections (i.e. refer to an item).

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See docs regarding deleting [by comment id](DELETE method) or [by item/field identifier](https://doc.scrapinghub.com/api/comments.html#comments-project-id-spider-id-job-id-item-no-field) (DELETE method).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.App.Comments.delete("API_KEY", 456789)
  ScrapyCloudEx.Endpoints.App.Comments.delete("API_KEY", "14/13/12/11")
  ScrapyCloudEx.Endpoints.App.Comments.delete("API_KEY", "14/13/12/11/logo")
  ```
  """
  @spec delete(String.t(), integer | String.t(), Keyword.t()) :: ScrapyCloudEx.result()
  def delete(api_key, id, opts \\ [])
      when is_api_key(api_key)
      when is_integer(id) or (is_binary(id) and id != "")
      when is_list(opts) do
    case basic_comment_request(api_key, id, [], opts, :delete) do
      %RequestConfig{} = request -> request |> Helpers.make_request()
      error -> {:error, error}
    end
  end

  @doc """
  Retrieves the number of items with unarchived comments by job.

  Returns a map containing job ids as keys, and unarchived comment counts as values. Only
  jobs with unarchived comments are present in the map.

  Refer to the documentation for `ScrapyCloudEx.Endpoints` to learn about the `opts` value.

  See [docs](https://doc.scrapinghub.com/api/comments.html#comments-project-id-stats).

  ## Example

  ```
  ScrapyCloudEx.Endpoints.App.Comments.stats("API_KEY", "123")
  ```
  """
  @spec stats(String.t(), String.t() | integer, Keyword.t()) :: ScrapyCloudEx.result()
  def stats(api_key, project_id, opts \\ [])
      when is_api_key(api_key)
      when is_binary(project_id)
      when is_list(opts) do
    RequestConfig.new()
    |> RequestConfig.put(:api_key, api_key)
    |> RequestConfig.put(:opts, opts)
    |> RequestConfig.put(:url, [@base_url, project_id, "stats"] |> merge_sections())
    |> Helpers.make_request()
  end

  @spec basic_comment_request(String.t(), String.t(), Keyword.t(), Keyword.t(), atom) ::
          RequestConfig.t() | ScrapyCloudEx.tagged_error_info()
  defp basic_comment_request(api_key, composite_id, params, opts, method) do
    with :ok <- Helpers.validate_params(params, [:text]),
         :ok <- check_constraints(method, composite_id, params) do
      RequestConfig.new()
      |> RequestConfig.put(:api_key, api_key)
      |> RequestConfig.put(:method, method)
      |> RequestConfig.put(:body, params)
      |> RequestConfig.put(:opts, opts)
      |> RequestConfig.put(:url, [@base_url, composite_id] |> Enum.join("/"))
    else
      {:invalid_param, _} = error -> error
    end
  end

  @spec check_constraints(atom, String.t(), Keyword.t()) ::
          :ok | ScrapyCloudEx.tagged_error_info()
  defp check_constraints(method, composite_id, params)
       when is_atom(method)
       when is_binary(composite_id) or is_integer(composite_id)
       when is_list(params) do
    do_check_constraints(method, section_count(composite_id), Keyword.has_key?(params, :text))
  end

  @spec do_check_constraints(atom, integer, boolean) :: :ok | ScrapyCloudEx.tagged_error_info()

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

  @spec required_text_param_not_provided() :: ScrapyCloudEx.tagged_error_info()
  defp required_text_param_not_provided() do
    "required `text` param not provided" |> Helpers.invalid_param_error(:text)
  end

  @spec merge_sections([String.t()]) :: String.t()
  defp merge_sections(sections), do: sections |> Enum.join("/")

  @spec section_count(String.t()) :: integer

  defp section_count(composite) when is_integer(composite), do: 1

  defp section_count(composite) when is_binary(composite),
    do: composite |> String.split("/") |> length()
end
