defmodule Test.Support.HttpAdapters.Passthrough do
  @behaviour ScrapyCloudEx.HttpAdapter

  @impl ScrapyCloudEx.HttpAdapter
  def request(request_config), do: request_config
end
