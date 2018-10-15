defmodule ScrapyCloudEx.Decoders.Default do
  @moduledoc """
  A default implementation of the `ScrapyCloudEx.Decoder` behaviour.

  This decoder uses `Jason` to decode JSON values data, all other return types
  are simply forwarded without transformation.
  """

  alias ScrapyCloudEx.Decoder

  @behaviour Decoder

  @impl Decoder

  @spec decode(String.t, atom) :: {:ok, any} | ScrapyCloudEx.tagged_error

  def decode(body, :json), do: Jason.decode(body)

  def decode(body, _), do: {:ok, body}
end
