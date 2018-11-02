defmodule ScrapyCloudEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :scrapy_cloud_ex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Docs
      name: "ScrapyCloudEx",
      source_url: "https://github.com/davidsulc/scrapy_cloud_ex",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.14", only: [:dev, :test]},
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:httparrot, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      # TODO update once v. > "0.19.1" is available
      {:ex_doc, git: "https://github.com/elixir-lang/ex_doc.git", ref: "f006883de3400e5e4fdfbe421b63ef919d3cf7ef", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs() do
    [
      main: "ScrapyCloudEx",
      extras: ["README.md"],
      groups_for_modules: [
        "Endpoints": [
          ScrapyCloudEx.Endpoints,
          ScrapyCloudEx.Endpoints.App.Comments,
          ScrapyCloudEx.Endpoints.App.Jobs,
          ScrapyCloudEx.Endpoints.Storage,
          ScrapyCloudEx.Endpoints.Storage.Activity,
          ScrapyCloudEx.Endpoints.Storage.Items,
          ScrapyCloudEx.Endpoints.Storage.JobQ,
          ScrapyCloudEx.Endpoints.Storage.Logs,
          ScrapyCloudEx.Endpoints.Storage.Requests
        ],
        "Default implementations": [
          ScrapyCloudEx.Decoders.Default,
          ScrapyCloudEx.HttpAdapters.Default
        ],
        "Custom implementations": [
          ScrapyCloudEx.Decoder,
          ScrapyCloudEx.HttpAdapter,
          ScrapyCloudEx.HttpAdapter.RequestConfig,
          ScrapyCloudEx.HttpAdapter.Response
        ]
      ],
      nest_modules_by_prefix: [
        ScrapyCloudEx.Decoders,
        ScrapyCloudEx.HttpAdapter,
        ScrapyCloudEx.HttpAdapters,
        ScrapyCloudEx.Endpoints.App,
        ScrapyCloudEx.Endpoints.Storage
      ]
    ]
  end
end
