# ScrapyCloudEx

An API wrapper for the ScrapyCloud API provided by ScraphingHub.com and documented [here](https://doc.scrapinghub.com/scrapy-cloud.html]

The implementation is only partial at this time: among the endpoints listed [here](https://doc.scrapinghub.com/scrapy-cloud.html#api-endpoints), the [`Collections`](https://doc.scrapinghub.com/api/collections.html) and [`Frontier`](https://doc.scrapinghub.com/api/frontier.html) are not accessible through this wrapper (PRs welcome!).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `scrapy_cloud_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scrapy_cloud_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/scrapy_cloud_ex](https://hexdocs.pm/scrapy_cloud_ex).

