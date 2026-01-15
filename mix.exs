defmodule Sashite.Cell.MixProject do
  use Mix.Project

  @version "2.0.0"
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
      docs: docs(),

      # Quality tools
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    CELL (Coordinate Encoding for Layered Locations) implementation for Elixir.
    Provides a standardized ASCII format for encoding protocol-level Location
    identifiers on multi-dimensional Boards.
    """
  end

  defp package do
    [
      name: "sashite_cell",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Specification" => "https://sashite.dev/specs/cell/1.0.0/",
        "Documentation" => "https://hexdocs.pm/sashite_cell"
      },
      maintainers: ["Cyril Kato"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      source_ref: "v#{@version}"
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix],
      flags: [
        :unmatched_returns,
        :error_handling,
        :no_opaque,
        :unknown,
        :no_return
      ]
    ]
  end
end
