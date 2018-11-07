# ScrapyCloudEx

An API wrapper for the ScrapyCloud API provided by ScraphingHub.com and documented [here](https://doc.scrapinghub.com/scrapy-cloud.html)

The implementation is only partial at this time: among the endpoints listed [here](https://doc.scrapinghub.com/scrapy-cloud.html#api-endpoints), the [`Collections`](https://doc.scrapinghub.com/api/collections.html) and [`Frontier`](https://doc.scrapinghub.com/api/frontier.html) are not accessible through this wrapper (PRs welcome!).

This wrapper handles Http communication and reponse decoding for you (provided you install the dependencies below), but
will only request the `json` format by default, and will only decode `json` responses. Other response types are passed
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

For the "It Just Works" experience, simply add the above 3 dependencies to your project.

If you know what you're doing and want to use custom implentations of http clients or response decoders,
feel free to include only `:scrapy_cloud_ex` as a dependency and refer to the "custom implementations"
section of the [documentation](https://hexdocs.pm/scrapy_cloud_ex) sidebar.

## Basic Usage

To interact with the API endpoints, use the various modules prefixed with `ScrapyCloudEx.Endpoints`.

```
iex(1)> ScrapyCloudEx.Endpoints.Storage.Items.get("API_KEY", "53/34/7", pagination: [count: 10])
```

Where `"API_KEY"` is your API key (which you can find [here](https://app.scrapinghub.com/account/apikey))
and `"53/34/7"` is a job id.

The docs can be found at [https://hexdocs.pm/scrapy_cloud_ex](https://hexdocs.pm/scrapy_cloud_ex).

## Troubleshooting missing dependencies

The default implementations of the http adapter and decoder require their dependencies to be present (see [installation](#installation) section).

After adding the dependencies for the default implementation you wish to use (and fetching them with `mix deps.get`),
delete the `_build` directory and recompile. This will ensure that the modules for the default implementation will be
properly recompiled according to the newly available dependencies.

## License

Copyright 2018 David Sulc

This library is released under the Apache 2.0 License - see the
[LICENSE](https://raw.githubusercontent.com/davidsulc/scrapy_cloud_ex/master/LICENSE) file.

