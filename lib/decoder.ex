defmodule ScrapyCloudEx.Decoder do
  @type format :: :json | :jl | :xml | :csv | :text

  @callback decode(body :: String.t(), format :: format) ::
              {:ok, any} | ScrapyCloudEx.tagged_error
end
