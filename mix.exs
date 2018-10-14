defmodule ScrapyCloudEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :scrapy_cloud_ex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
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
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
