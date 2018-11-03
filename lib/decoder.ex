defmodule ScrapyCloudEx.Decoder do
  @moduledoc """
  Defines the behaviour used to process the body of API responses.

  A module implementing this behaviour can be used for decoding API response bodies
  by using the `:decoder` key in the [`opts`](ScrapyCloudEx.Endpoints.html#module-options)
  parameter of every endpoint module.
  """

  @type format :: :json | :jl | :xml | :csv | :text | :html

  @typedoc """
  A function to decode a response body.

  This decoder function will be provided the (uncompressed) reponse `body`
  and the requested `format`. It should return `{:ok, term()} | {:error, term()}`
  where `:ok` and `:error` indicate whether decoding the body was successful.
  """
  @type decoder_function ::
          (body :: String.t(), format :: format() ->
             {:ok, any} | ScrapyCloudEx.tagged_error())

  @doc """
  Decodes the `format`-encoded `body` of an API response.
  """
  @callback decode(body :: String.t(), format :: format) ::
              {:ok, any} | ScrapyCloudEx.tagged_error()
end
