defmodule ScrapyCloudEx.Decoders.Default do
  alias ScrapyCloudEx.Decoder

  @behaviour Decoder

  @impl Decoder
  def decode(body, :json), do: Jason.decode(body)

  def decode(body, _), do: {:ok, body}
end
