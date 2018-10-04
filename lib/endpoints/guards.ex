defmodule ScrapyCloudEx.Endpoints.Guards do
  defguard is_api_key(key) when is_binary(key)

  defguard is_id(id) when is_binary(id) or is_integer(id)
end
