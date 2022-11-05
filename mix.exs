defmodule CompareChain.MixProject do
  use Mix.Project

  @source_url "https://github.com/CargoSense/compare_chain"
  @version "0.2.0"

  def project do
    [
      app: :compare_chain,
      deps: deps(),
      docs: docs(),
      elixir: "~> 1.14",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: @version
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
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      source_url: @source_url,
      source_ref: "v#{@version}",
      deps: [],
      language: "en",
      formatters: ["html"],
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end

  defp package do
    [
      description: "Chained, semantic comparisons for Elixir",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
