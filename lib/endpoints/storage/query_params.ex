defmodule ScrapyCloudEx.Endpoints.Storage.QueryParams do
  @moduledoc false

  require Logger

  @type t :: %__MODULE__{}

  @default_format :json

  @param_aliases [
    {:line_end, :lineend},
    {:no_data, :nodata},
    {:start_after, :startafter}
  ]

  alias ScrapyCloudEx.Endpoints
  alias ScrapyCloudEx.Endpoints.{Helpers, Storage}

  defstruct [
    :error,
    :nodata,
    :meta,
    :format,
    csv: [],
    pagination: []
  ]

  @spec from_keywords(Keyword.t()) :: t
  def from_keywords(params) when is_list(params) do
    sanitized_params =
      params
      |> sanitize()
      |> configure_pagination()
      |> configure_csv()

    case Helpers.validate_params(sanitized_params, [:format, :meta, :nodata, :pagination, :csv]) do
      :ok ->
        __MODULE__
        |> struct(sanitized_params)
        |> warn_on_inconsistent_format()
        |> set_defaults()
        |> validate_params()

      error ->
        error
    end
  end

  @spec warn_if_no_pagination(t, String.t()) :: t
  def warn_if_no_pagination(%__MODULE__{} = params, function_name) do
    if !has_pagination?(params) do
      Logger.warn("#{function_name} called without pagination params or index")
    end

    params
  end

  @spec to_query(t) :: String.t() | ScrapyCloudEx.tagged_error()

  def to_query(%__MODULE__{error: nil} = params) do
    params
    |> Map.from_struct()
    |> Enum.to_list()
    |> Enum.map(&to_keyword_list/1)
    |> List.flatten()
    |> URI.encode_query()
  end

  def to_query(%__MODULE__{error: error}), do: {:error, error}

  @spec has_pagination?(t) :: boolean

  defp has_pagination?(%__MODULE__{pagination: pagination_params}) do
    case Keyword.get(pagination_params, :index) do
      [] -> Keyword.delete(pagination_params, :index) != []
      _ -> true
    end
  end

  defp has_pagination?(%__MODULE__{}), do: false

  @spec to_keyword_list(tuple) :: Keyword.t()

  defp to_keyword_list({group, params}) when group in [:pagination, :csv] do
    params
    |> Enum.map(&to_keyword_list/1)
    |> List.flatten()
  end

  defp to_keyword_list({:fields, fields}), do: {:fields, fields |> Enum.join(",")}

  defp to_keyword_list({_, empty}) when empty == nil or empty == [], do: []

  defp to_keyword_list({k, v}) when is_list(v), do: v |> Enum.map(&{k, &1})

  defp to_keyword_list({_, v} = pair) when is_atom(v) or is_integer(v) or is_binary(v), do: pair

  defp to_keyword_list({_, _}), do: []

  @spec sanitize(Keyword.t()) :: Keyword.t()
  defp sanitize(params) when is_list(params) do
    if Keyword.keyword?(params) do
      params
      |> Helpers.canonicalize_params(@param_aliases)
      |> Enum.map(&sanitize_param/1)
    else
      params
    end
  end

  @spec sanitize_param({atom, any}) :: {atom, any}

  defp sanitize_param({:include_headers, false}), do: {:include_headers, 0}
  defp sanitize_param({:include_headers, true}), do: {:include_headers, 1}
  defp sanitize_param({:include_headers, v}), do: {:include_headers, v}

  defp sanitize_param({:nodata, false}), do: {:nodata, 0}
  defp sanitize_param({:nodata, true}), do: {:nodata, 1}
  defp sanitize_param({:nodata, v}), do: {:nodata, v}

  defp sanitize_param({k, v}) when is_list(v), do: {k, sanitize(v)}

  defp sanitize_param({_, _} = pair), do: pair

  @spec configure_pagination(Keyword.t()) :: Keyword.t()
  defp configure_pagination(params) do
    Endpoints.scope_params(params, :pagination, Storage.pagination_params())
  end

  @spec configure_csv(Keyword.t()) :: Keyword.t()
  defp configure_csv(params) do
    Endpoints.scope_params(params, :csv, Storage.csv_params())
  end

  @spec warn_on_inconsistent_format(t) :: t

  defp warn_on_inconsistent_format(%{format: format, csv: [_ | _]} = params)
       when format not in [:csv, nil] do
    Logger.warn("CSV parameters provided, but requested format is #{inspect(format)}")
    params
  end

  defp warn_on_inconsistent_format(%{format: nil, csv: [_ | _]} = params) do
    Logger.info("Setting `format` to :csv since `:csv` parameters were provided")
    %{params | format: :csv}
  end

  defp warn_on_inconsistent_format(params), do: params

  @spec set_defaults(t) :: t

  defp set_defaults(%{format: nil} = params) do
    %{params | format: @default_format}
  end

  defp set_defaults(%{} = params), do: params

  @spec validate_params(t) :: t
  defp validate_params(params) do
    params
    |> validate_format()
    |> validate_meta()
    |> validate_nodata()
    |> validate_pagination()
  end

  @spec validate_optional_positive_integer_form(nil, atom) ::
          :ok | ScrapyCloudEx.tagged_error_info()

  defp validate_optional_positive_integer_form(nil, _tag), do: :ok

  defp validate_optional_positive_integer_form(value, _tag) when is_integer(value) and value > 0,
    do: :ok

  defp validate_optional_positive_integer_form(value, tag) when is_binary(value) do
    if String.match?(value, ~r/^\d+$/) do
      :ok
    else
      "expected only digits, was given #{inspect(value)}"
      |> Helpers.invalid_param_error(tag)
    end
  end

  defp validate_optional_positive_integer_form(value, tag) do
    value |> expected_positive_integer_form(tag)
  end

  @spec validate_format(t) :: t

  defp validate_format(%{format: :csv} = params) do
    params
    |> validate_csv_params()
    |> check_fields_param_provided()
  end

  defp validate_format(%{format: format} = params) do
    case Storage.validate_format(format) do
      :ok -> params
      error -> %{params | error: error}
    end
  end

  @spec validate_csv_params(t) :: t
  defp validate_csv_params(%{csv: csv} = params) do
    case Helpers.validate_params(csv, Storage.csv_params()) do
      :ok ->
        params

      {:invalid_param, error} ->
        %{params | error: error |> Helpers.invalid_param_error(:csv_param)}
    end
  end

  @spec check_fields_param_provided(t) :: t
  defp check_fields_param_provided(%{csv: csv} = params) do
    if Keyword.has_key?(csv, :fields) do
      params
    else
      error =
        "required attribute 'fields' not provided"
        |> Helpers.invalid_param_error(:csv_param)

      %{params | error: error}
    end
  end

  @spec validate_meta(t) :: t

  defp validate_meta(%{meta: nil} = params), do: params

  defp validate_meta(%{meta: meta} = params) when is_list(meta) do
    case Helpers.validate_params(meta, Storage.meta_params()) do
      :ok -> params
      {:invalid_param, error} -> %{params | error: error |> Helpers.invalid_param_error(:meta)}
    end
  end

  defp validate_meta(params) do
    %{params | error: "expected a list" |> Helpers.invalid_param_error(:meta)}
  end

  @spec validate_nodata(t) :: t

  defp validate_nodata(%{nodata: nil} = params), do: params

  defp validate_nodata(%{nodata: nodata} = params) when nodata in [0, 1], do: params

  defp validate_nodata(params) do
    %{params | error: "expected a boolean value" |> Helpers.invalid_param_error(:nodata)}
  end

  @spec validate_pagination(t) :: t
  defp validate_pagination(params) do
    params
    |> validate_pagination_params()
    |> validate_pagination_count()
    |> validate_pagination_start()
    |> validate_pagination_startafter()
    |> process_pagination_index()
    |> validate_pagination_index()
  end

  @spec validate_pagination_params(t) :: t
  defp validate_pagination_params(%{pagination: pagination} = params) do
    case Helpers.validate_params(pagination, Storage.pagination_params()) do
      :ok ->
        params

      {:invalid_param, error} ->
        %{params | error: error |> Helpers.invalid_param_error(:pagination)}
    end
  end

  @spec validate_pagination_count(t) :: t
  defp validate_pagination_count(%{pagination: pagination} = params) do
    case validate_optional_positive_integer_form(Keyword.get(pagination, :count), :count) do
      :ok ->
        params

      {:invalid_param, error} ->
        %{params | error: error |> Helpers.invalid_param_error(:pagination)}
    end
  end

  @spec validate_pagination_start(t) :: t
  defp validate_pagination_start(params), do: params |> validate_pagination_offset(:start)

  @spec validate_pagination_startafter(t) :: t
  defp validate_pagination_startafter(params),
    do: params |> validate_pagination_offset(:startafter)

  @spec validate_pagination_offset(t, atom) :: t
  defp validate_pagination_offset(%{pagination: pagination} = params, offset_name) do
    with nil <- Keyword.get(pagination, offset_name) do
      params
    else
      id ->
        case id |> validate_full_form_id(offset_name) do
          :ok ->
            params

          {:invalid_param, error} ->
            %{params | error: error |> Helpers.invalid_param_error(:pagination)}
        end
    end
  end

  @spec process_pagination_index(t) :: t
  defp process_pagination_index(%{pagination: pagination} = params) do
    # the :index key could be given multiple times, so we collect all values into an array
    # which we need to flatten, because it could already have been given as a list
    index =
      pagination
      |> Keyword.get_values(:index)
      |> List.flatten()

    %{params | pagination: pagination |> Keyword.put(:index, index)}
  end

  @spec validate_pagination_index(t) :: t
  defp validate_pagination_index(%{pagination: pagination} = params) do
    pagination
    |> Keyword.get(:index)
    |> reduce_indexes_to_first_error()
    |> case do
      :ok ->
        params

      {:invalid_param, error} ->
        %{params | error: error |> Helpers.invalid_param_error(:pagination)}
    end
  end

  @spec reduce_indexes_to_first_error(Keyword.t()) :: :ok | ScrapyCloudEx.tagged_error_info()
  defp reduce_indexes_to_first_error(indexes) do
    reducer = fn i, acc ->
      case validate_optional_positive_integer_form(i, :index) do
        :ok -> {:cont, acc}
        {:invalid_param, _} = error -> {:halt, error}
      end
    end

    indexes |> Enum.reduce_while(:ok, reducer)
  end

  @spec validate_full_form_id(String.t(), atom) :: :ok | ScrapyCloudEx.tagged_error_info()

  defp validate_full_form_id(id, tag) when not is_binary(id),
    do: "expected a string" |> Helpers.invalid_param_error(tag)

  defp validate_full_form_id(id, tag) do
    if id |> String.split("/") |> Enum.reject(&(&1 == "")) |> length() == 4 do
      :ok
    else
      "expected a full id with exactly 4 parts"
      |> Helpers.invalid_param_error(tag)
    end
  end

  @spec expected_positive_integer_form(any, atom) :: ScrapyCloudEx.tagged_error_info()
  defp expected_positive_integer_form(value, tag) do
    "expected a positive integer (possibly represented as a string), was given #{inspect(value)}"
    |> Helpers.invalid_param_error(tag)
  end
end
