defmodule ScrapyCloudEx do
  @type error_info :: String.t | tagged_error_info
  @type result :: {:ok, any} | tagged_error
  @type tagged_error :: {:error, error_info}
  @type tagged_error_info :: {atom, error_info}
end
