defmodule Sashite.Cell.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/sashite/cell.ex"

  def project do
    [
      app: :sashite_cell,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Documentation
      name: "Sashite.Cell",
      source_url: @source_url,
      homepage_url: "https://sashite.dev/specs/cell/",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE.md"]
      ]
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
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    CELL (Coordinate Encoding for Layered Locations) implementation for Elixir.
    Provides a standardized ASCII format for encoding protocol-level Location identifiers on multi-dimensional Boards.
    """
  end

  defp package do
    [
      name: "sashite_cell",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Specification" => "https://sashite.dev/specs/cell/1.0.0/",
        "Documentation" => "https://hexdocs.pm/sashite_cell"
      },
      maintainers: ["Cyril Kato"]
    ]
  end
end
