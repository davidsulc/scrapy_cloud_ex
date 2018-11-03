# ScrapyCloudEx

An API wrapper for the ScrapyCloud API provided by ScraphingHub.com and documented [here](https://doc.scrapinghub.com/scrapy-cloud.html)

The implementation is only partial at this time: among the endpoints listed [here](https://doc.scrapinghub.com/scrapy-cloud.html#api-endpoints), the [`Collections`](https://doc.scrapinghub.com/api/collections.html) and [`Frontier`](https://doc.scrapinghub.com/api/frontier.html) are not accessible through this wrapper (PRs welcome!).

This wrapper handles Http communication and reponse decoding for you (provided you install the dependencies below), but
will only request the `json` format by default, and will only decoder `json` responses. Other response types are passed
through, allowing you to process them if desired. If you prefer to use your own Http adapter or function to decode the
body, refer to the "custom implementations" section in the documentation.

## Installation

The package can be installed by adding `scrapy_cloud_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scrapy_cloud_ex, "~> 0.1.0"},

    # Optional dependencies

    # add this to use the default HttpAdapter
    {:hackney, "~> 1.14"},
    # add this to use the default Decoder
    {:jason, "~> 1.1"}
  ]
end
```

## Basic Usage

To interact with the API endpoints, use the various modules prefixed with `ScrapyCloudEx.Endpoints`.

```
iex(1)> ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7", pagination: [count: 10])
```

Where `"API_KEY"` is your API key (which you can find [here](https://app.scrapinghub.com/account/apikey))
and `"53/34/7"` is a job id.

The docs can be found at [https://hexdocs.pm/scrapy_cloud_ex](https://hexdocs.pm/scrapy_cloud_ex).

## License

Copyright 2018 David Sulc

This library is released under the Apache 2.0 License - see the
[LICENSE](https://raw.githubusercontent.com/davidsulc/scrapy_cloud_ex/master/LICENSE) file.

