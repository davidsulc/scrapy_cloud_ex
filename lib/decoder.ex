defmodule ScrapyCloudEx.Decoder do
  @moduledoc """
  Defines the Decoder behaviour used to process the body of API responses.
  """

  @type format :: :json | :jl | :xml | :csv | :text | :html
  @type decoder_function :: (String.t, atom -> any)

  @doc """
  Decodes the `format`-encoded `body` of an API response.
  """
  @callback decode(body :: String.t(), format :: format) ::
              {:ok, any} | ScrapyCloudEx.tagged_error
end
