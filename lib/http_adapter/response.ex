defmodule ScrapyCloudEx.HttpAdapter.Response do
  @type t :: %__MODULE__{}

  defstruct [:status, :headers, :body]
end
