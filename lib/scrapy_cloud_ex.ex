defmodule ScrapyCloudEx do
  @type result :: {:ok, any} | {:error, tagged_error}
  @type tagged_error :: {atom, String.t | tagged_error}
end
