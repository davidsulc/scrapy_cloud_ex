defmodule ScrapyCloudEx.Decoders.PassThrough do
  alias ScrapyCloudEx.Decoder

  @behaviour Decoder

  @impl Decoder
  def decode(body, _), do: {:ok, body}
end
