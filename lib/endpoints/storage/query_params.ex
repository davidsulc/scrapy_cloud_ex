defmodule ScrapingHubEx.Endpoints.Storage.QueryParams do
  @moduledoc false

  require Logger

  @default_format :json

  # parameter naming in the API is a bit inconsistent where multi-words variables are concerned
  # (e.g. include_headers vs lineend) and often doesn't conform to the Elixir convention of
  # snake_casing variables composed of multiple words, so this will allow us to accept both (e.g.)
  # `line_end` and `lineend` and convert them to the name the API expects
  @param_synonyms [
    {:includeheaders, :include_headers},
    {:line_end, :lineend},
    {:no_data, :nodata},
    {:start_after, :startafter}
  ]
  @param_synonyms_available @param_synonyms |> Keyword.keys()

  alias ScrapingHubEx.Endpoints.{Helpers, Storage}

  defstruct [
    :error,
    :nodata,
    :meta,
    :format,
    csv: [],
    pagination: []
  ]

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
        {:error, error}
    end
  end

  def warn_if_no_pagination(%__MODULE__{} = params, function_name) do
    if !has_pagination?(params) do
      Logger.warn("#{function_name} called without pagination params or index")
    end

    params
  end

  def has_pagination?(%__MODULE__{pagination: pagination_params}) do
    case Keyword.get(pagination_params, :index) do
      [] -> Keyword.delete(pagination_params, :index) != []
      _ -> true
    end
  end

  def has_pagination?(%__MODULE__{}), do: false

  def to_query(%__MODULE__{error: nil} = params) do
    params
    |> Map.from_struct()
    |> Enum.to_list()
    |> Enum.map(&to_keyword_list/1)
    |> List.flatten()
    |> URI.encode_query()
  end

  def to_query(%__MODULE__{error: error}), do: {:error, error}

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

  defp sanitize(params) when is_list(params) do
    if Keyword.keyword?(params) do
      params |> Enum.map(&sanitize_param/1)
    else
      params
    end
  end

  defp sanitize_param({k, v}) when k in @param_synonyms_available do
    replacement = Keyword.get(@param_synonyms, k)
    Logger.warn("replacing '#{inspect(k)}' parameter with '#{inspect(replacement)}'")

    {replacement, v}
    |> sanitize_param()
  end

  defp sanitize_param({:include_headers, false}), do: {:include_headers, 0}
  defp sanitize_param({:include_headers, true}), do: {:include_headers, 1}
  defp sanitize_param({:include_headers, v}), do: {:include_headers, v}

  defp sanitize_param({:nodata, false}), do: {:nodata, 0}
  defp sanitize_param({:nodata, true}), do: {:nodata, 1}
  defp sanitize_param({:nodata, v}), do: {:nodata, v}

  defp sanitize_param({k, v}) when is_list(v), do: {k, sanitize(v)}

  defp sanitize_param({_, _} = pair), do: pair

  defp configure_pagination(params) do
    params |> configure_params(:pagination, Storage.pagination_params())
  end

  defp configure_csv(params) do
    params |> configure_params(:csv, Storage.csv_params())
  end

  defp configure_params(params, scope_name, expected_scoped_params) do
    unscoped = params |> get_params(expected_scoped_params)
    scoped = Keyword.get(params, scope_name, [])

    warn_on_unscoped_params(scoped, unscoped, scope_name)

    scoped_params = unscoped |> Keyword.merge(scoped)

    params
    |> Enum.reject(fn {k, _} -> Enum.member?(expected_scoped_params, k) end)
    |> Keyword.put(scope_name, scoped_params)
  end

  defp get_params(params, keys) do
    keys
    |> Enum.map(&{&1, Keyword.get(params, &1)})
    |> Enum.reject(fn {_, v} -> v == nil end)
  end

  defp warn_on_unscoped_params(scoped, unscoped, scope_name) do
    if length(unscoped) > 0 do
      Logger.warn(
        "pagination values `#{inspect(unscoped)}` should be provided within the `#{scope_name}` parameter"
      )

      common_params = intersection(Keyword.keys(unscoped), Keyword.keys(scoped))

      if length(common_params) > 0 do
        Logger.warn(
          "top-level #{scope_name} params `#{inspect(common_params)}` will be overridden by values provided in `#{
            scope_name
          }` parameter"
        )
      end
    end
  end

  defp intersection(a, b) when is_list(a) and is_list(b) do
    items_only_in_a = a -- b
    a -- items_only_in_a
  end

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

  defp set_defaults(%{format: nil} = params) do
    %{params | format: @default_format}
  end

  defp set_defaults(%{} = params), do: params

  defp validate_params(params) do
    params
    |> validate_format()
    |> validate_meta()
    |> validate_nodata()
    |> validate_pagination()
  end

  defp validate_optional_integer_form(nil, _tag), do: :ok

  defp validate_optional_integer_form(value, _tag) when is_integer(value), do: :ok

  defp validate_optional_integer_form(value, tag) when is_binary(value) do
    if String.match?(value, ~r/^\d+$/) do
      :ok
    else
      "expected only digits, was given #{inspect(value)}"
      |> Helpers.invalid_param_error(tag)
    end
  end

  defp validate_optional_integer_form(value, tag) do
    value |> expected_integer_form(tag)
  end

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

  defp validate_csv_params(%{csv: csv} = params) do
    case Helpers.validate_params(csv, Storage.csv_params()) do
      :ok ->
        params

      {:invalid_param, error} ->
        %{params | error: error |> Helpers.invalid_param_error(:csv_param)}
    end
  end

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

  defp validate_nodata(%{nodata: nil} = params), do: params
  defp validate_nodata(%{nodata: nodata} = params) when nodata in [0, 1], do: params

  defp validate_nodata(params) do
    %{params | error: "expected a boolean value" |> Helpers.invalid_param_error(:nodata)}
  end

  defp validate_pagination(params) do
    params
    |> validate_pagination_params()
    |> validate_pagination_count()
    |> validate_pagination_start()
    |> validate_pagination_startafter()
    |> process_pagination_index()
    |> validate_pagination_index()
  end

  defp validate_pagination_params(%{pagination: pagination} = params) do
    case Helpers.validate_params(pagination, Storage.pagination_params()) do
      :ok ->
        params

      {:invalid_param, error} ->
        %{params | error: error |> Helpers.invalid_param_error(:pagination)}
    end
  end

  defp validate_pagination_count(%{pagination: pagination} = params) do
    case validate_optional_integer_form(Keyword.get(pagination, :count), :count) do
      :ok ->
        params

      {:invalid_param, error} ->
        %{params | error: error |> Helpers.invalid_param_error(:pagination)}
    end
  end

  defp validate_pagination_start(params), do: params |> validate_pagination_offset(:start)

  defp validate_pagination_startafter(params),
    do: params |> validate_pagination_offset(:startafter)

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

  defp process_pagination_index(%{pagination: pagination} = params) do
    # the :index key could be given multiple times, so we collect all values into an array
    # which we need to flatten, because it could already have been given as a list
    index =
      pagination
      |> Keyword.get_values(:index)
      |> List.flatten()

    %{params | pagination: pagination |> Keyword.put(:index, index)}
  end

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

  defp reduce_indexes_to_first_error(indexes) do
    reducer = fn i, acc ->
      case validate_optional_integer_form(i, :index) do
        :ok -> {:cont, acc}
        {:invalid_param, _} = error -> {:halt, error}
      end
    end

    indexes |> Enum.reduce_while(:ok, reducer)
  end

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

  defp expected_integer_form(value, tag) do
    "expected an integer (possibly represented as a string), was given #{inspect(value)}"
    |> Helpers.invalid_param_error(tag)
  end
end
