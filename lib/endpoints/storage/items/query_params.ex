defmodule SHEx.Endpoints.Storage.Items.QueryParams do
  @moduledoc false

  alias SHEx.Endpoints.{Helpers, Storage}

  defstruct [
    :error,
    :nodata,
    :meta,
    format: :json,
    csv_params: [],
    pagination: []
  ]

  def from_keywords(params) when is_list(params) do
    __MODULE__
    |> struct(params |> sanitize())
    |> configure_format()
    |> validate_params()
  end

  defp sanitize(params) when is_list(params) do
    params |> Enum.map(&sanitize_param/1)
  end

  defp sanitize_param({:no_data, v}), do: {:nodata, v} |> sanitize_param()

  defp sanitize_param({:nodata, false}), do: {:nodata, 0}
  defp sanitize_param({:nodata, true}), do: {:nodata, 1}
  defp sanitize_param({:nodata, v}), do: {:nodata, v}

  defp sanitize_param({_, _} = pair), do: pair

  defp configure_format(params) do
    params |> process_csv_format()
  end

  defp validate_params(params) do
    params
    |> validate_format()
    |> validate_meta()
    |> validate_nodata()
    |> validate_pagination()
  end

  defp process_csv_format(%{format: format} = params) when is_list(format) do
    if Keyword.keyword?(format) do
      params |> set_csv_attributes()
    else
      error =
        "unexpected list value: #{inspect(format)}"
        |> Helpers.invalid_param_error(:format)

      %{params | error: error}
    end
  end

  defp process_csv_format(params), do: params

  defp set_csv_attributes(%{format: format} = params) do
    # we're determining the csv format this way so that a typo like
    # format: [csv: [fields: ["auction", "id"]], sep: ","]
    # instead of
    # format: [csv: [fields: ["auction", "id"], sep: ","]]
		# gets a better error message:
    # {:invalid_param,
    #    {:format,
    #        "multiple values provided: [csv: [fields: [\"auction\", \"id\"]], sep: \",\"]"}}
		# instead of
		# {:invalid_param,
    #    {:format,
    #        "expected format '[csv: [fields: [\"auction\", \"id\"]], sep: \",\"]' to be one of:
    #         [:json, :jl, :xml, :csv, :text]"}}
    case Keyword.get(format, :csv) do
      nil -> params
      csv_params ->
        if length(format) == 1 do
          %{params | format: :csv, csv_params: csv_params}
        else
          error =
            "multiple values provided: #{inspect(format)}"
            |> Helpers.invalid_param_error(:format)

          %{params | error: error}
        end
    end
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

  defp validate_csv_params(%{csv_params: csv} = params) do
    case Helpers.validate_params(csv, Storage.csv_params()) do
      :ok -> params
      {:invalid_param, error} -> %{params | error: error |> Helpers.invalid_param_error(:csv_param)}
    end
  end

  defp check_fields_param_provided(%{csv_params: csv} = params) do
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
  defp validate_meta(%{meta: meta} = params) do
    case Helpers.validate_params(meta, Storage.meta_params()) do
      :ok -> params
      {:invalid_param, error} -> %{params | error: error |> Helpers.invalid_param_error(:meta)}
    end
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
      :ok -> params
      {:invalid_param, error} -> %{params | error: error |> Helpers.invalid_param_error(:pagination)}
    end
  end

  defp validate_pagination_count(%{pagination: pagination} = params) do
    case validate_optional_integer_form(Keyword.get(pagination, :count), :count) do
      :ok -> params
      {:invalid_param, error} -> %{params | error: error |> Helpers.invalid_param_error(:pagination)}
    end
  end

  defp validate_pagination_start(params), do: params |> validate_pagination_offset(:start)

  defp validate_pagination_startafter(params), do: params |> validate_pagination_offset(:startafter)

  defp validate_pagination_offset(%{pagination: pagination} = params, offset_name) do
    with nil <- Keyword.get(pagination, offset_name) do
      params
    else
      id ->
        case id |> validate_full_form_id(offset_name) do
          :ok -> params
          {:invalid_param, error} -> %{params | error: error |> Helpers.invalid_param_error(:pagination)}
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
      :ok -> params
      {:invalid_param, error} -> %{params | error: error |> Helpers.invalid_param_error(:pagination)}
    end
  end

  defp reduce_indexes_to_first_error(indexes) do
    IO.inspect indexes
    reducer = fn i, acc ->
      case validate_optional_integer_form(i, :index) do
        :ok -> {:cont, acc}
        {:invalid_param, _} = error -> {:halt, error}
      end
    end

    indexes |> Enum.reduce_while(:ok, reducer)
  end

  defp validate_full_form_id(id, tag) when not is_binary(id), do: "expected a string" |> Helpers.invalid_param_error(tag)
  defp validate_full_form_id(id, tag) do
    if id |> String.split("/") |> Enum.reject(& &1 == "") |> length() == 4 do
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
