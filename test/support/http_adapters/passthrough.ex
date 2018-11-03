defmodule Test.Support.HttpAdapters.Passthrough do
  @moduledoc false

  @behaviour ScrapyCloudEx.HttpAdapter

  alias ScrapyCloudEx.HttpAdapter.Response

  @impl ScrapyCloudEx.HttpAdapter
  def request(request_config), do: {:ok, %Response{body: request_config}}

  @impl ScrapyCloudEx.HttpAdapter
  def handle_response(%Response{body: body}, _opts), do: body
end
