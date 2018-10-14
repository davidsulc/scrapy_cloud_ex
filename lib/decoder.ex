defmodule ScrapyCloudEx.Decoder do
  @type format :: :json | :jl | :xml | :csv | :text
  @type decoder_function :: (String.t, atom -> any)

  @callback decode(body :: String.t(), format :: format) ::
              {:ok, any} | ScrapyCloudEx.tagged_error
end
