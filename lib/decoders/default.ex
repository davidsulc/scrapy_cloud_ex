defmodule ScrapyCloudEx.Decoders.Default do
  alias ScrapyCloudEx.Decoder

  @behaviour Decoder

  @impl Decoder

  @spec decode(String.t, atom) :: {:ok, any} | ScrapyCloudEx.tagged_error

  def decode(body, :json), do: Jason.decode(body)

  def decode(body, _), do: {:ok, body}
end
