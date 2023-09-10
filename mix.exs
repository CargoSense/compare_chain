defmodule CompareChain.MixProject do
  use Mix.Project

  @source_url "https://github.com/CargoSense/compare_chain"
  @version "0.4.0"

  def project do
    [
      app: :compare_chain,
      deps: deps(),
      docs: docs(),
      elixir: ">= 1.13.0",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  # Run `mix help compile.app` to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run `mix help deps` to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  # Run `mix docs` to generate documentation.
  defp docs do
    [
      deps: [],
      extras: ["README.md", "CHANGELOG.md"],
      formatters: ["html"],
      language: "en",
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package do
    [
      description: "Chained, semantic comparisons for Elixir",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
