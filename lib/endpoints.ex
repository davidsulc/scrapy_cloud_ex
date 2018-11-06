defmodule ScrapyCloudEx.Endpoints do
  @moduledoc """
  Documents commonalities between all endpoint-related functions.

  ## Options

  The last argument provided to most endpoint functions is a keyword list
  of options. These options are made available to the HttpAdapter during the
  API request.

  - `:decoder` - specifies how the response body should be processed. Can be
    a module implementing the `ScrapyCloudEx.Decoder` behaviour, or a function
    conforming to the `t:ScrapyCloudEx.Decoder.decoder_function/0` typespec.
    Defaults to `ScrapyCloudEx.Decoders.Default`.

  - `:headers` - list of headers that are added to the `ScrapyCloudEx.HttpAdapter.RequestConfig`
    `headers` attribute provided to the HttpAdapter instance making the API call.
    The default HttpAdapter does not make use of this option.

  - `:http_adapter` - specifies the module to use to make the HTTP request to
    the API. This module is expected to implement the `ScrapyCloudEx.HttpAdapter`
    behaviour. Defaults to `ScrapyCloudEx.HttpAdapters.Default`.
  """

  require Logger

  # warns on unscoped params and puts relevant parameters into scope
  @doc false
  @spec scope_params(Keyword.t(), atom, [atom, ...]) :: Keyword.t()
  def scope_params(params, scope_name, expected_scoped_params) do
    unscoped = params |> get_params(expected_scoped_params)
    scoped = Keyword.get(params, scope_name, [])

    warn_on_unscoped_params(scoped, unscoped, scope_name)

    scoped_params = unscoped |> Keyword.merge(scoped)

    params
    |> Enum.reject(fn {k, _} -> Enum.member?(expected_scoped_params, k) end)
    |> Keyword.put(scope_name, scoped_params)
  end

  @doc false
  @spec merge_scope(Keyword.t(), atom()) :: Keyword.t()
  def merge_scope(params, scope) do
    scoped_params = Keyword.get(params, scope, [])

    params
    |> Keyword.merge(scoped_params)
    |> Keyword.delete(scope)
  end

  @spec get_params(Keyword.t(), [atom]) :: Keyword.t()
  defp get_params(params, keys) do
    keys
    |> Enum.map(&{&1, Keyword.get(params, &1)})
    |> Enum.reject(fn {_, v} -> v == nil end)
  end

  @spec warn_on_unscoped_params(Keyword.t(), Keyword.t(), atom) :: any
  defp warn_on_unscoped_params(scoped, unscoped, scope_name) do
    if length(unscoped) > 0 do
      Logger.warn(
        "values `#{inspect(unscoped)}` should be provided within the `#{scope_name}` parameter"
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

  @spec intersection(list, list) :: list
  defp intersection(a, b) when is_list(a) and is_list(b) do
    items_only_in_a = a -- b
    a -- items_only_in_a
  end
end
