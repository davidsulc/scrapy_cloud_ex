defmodule ScrapingHubEx.Decoders.PassThrough do
  alias ScrapingHubEx.Decoder

  @behaviour Decoder

  @impl Decoder
  def decode(body, _), do: {:ok, body}
end
