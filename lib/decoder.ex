defmodule ScrapyCloudEx.Decoder do
  @moduledoc """
  Defines the behaviour used to process the body of API responses.
  """

  @type format :: :json | :jl | :xml | :csv | :text | :html

  @typedoc """
  A decoder function that will be provided the (uncompressed) reponse `body`
  and the requested `format`.
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
