defmodule SHEx.Endpoints.Storage.Items.QueryParams do
  @moduledoc false

  alias SHEx.Endpoints.{Helpers, Storage}

  defstruct [
    :error,
    :item_index,
    :field_name,
    :pagination,
    :nodata,
    :meta,
    format: :json,
    csv_params: []
  ]

  def from_keywords(params) when is_list(params) do
    __MODULE__
    |> struct(params)
    |> configure_format()
    |> validate_params()
  end

  defp configure_format(params) do
    params |> process_csv_format()
  end

  defp validate_params(params) do
    params
    |> validate_item_index()
    |> validate_field_name()
    |> validate_format()
    |> validate_meta()
    |> validate_nodata()
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

  defp validate_item_index(%{item_index: index} = params) do
    case validate_optional_integer_form(index, :item_index) do
      :ok -> params
      {:invalid_param, _} = error -> %{params | error: error}
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

  defp validate_field_name(%{field_name: nil} = params), do: params
  defp validate_field_name(%{field_name: name} = params) when is_binary(name), do: params
  defp validate_field_name(params) do
    error =
      "expected a string"
      |> Helpers.invalid_param_error(:field_name)

    %{params | error: error}
  end

  defp validate_format(%{error: error} = params) when error != nil, do: params

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
  defp validate_nodata(%{nodata: nodata} = params) when is_boolean(nodata), do: params
  defp validate_nodata(params) do
    %{params | error: "expected a boolean value" |> Helpers.invalid_param_error(:nodata)}
  end

  defp expected_integer_form(value, tag) do
    "expected an integer (possibly represented as a string), was given #{inspect(value)}"
    |> Helpers.invalid_param_error(tag)
  end
end
