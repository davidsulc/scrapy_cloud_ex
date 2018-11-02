defmodule ScrapyCloudEx.HttpAdapter.Response do
  @type t :: %__MODULE__{}

  defstruct [:status, :headers, :body]

  @spec gzipped?(t) :: boolean
  def gzipped?(%__MODULE__{headers: headers}) do
    Enum.find(headers, false, fn
      {"Content-Encoding", "gzip"} -> true
      _ -> false
    end)
  end
end
