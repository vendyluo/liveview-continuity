defmodule LiveViewContinuity.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/vendyluo/liveview-continuity"

  def project do
    [
      app: :liveview_continuity,
      version: @version,
      elixir: ">= 1.18.0",
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      docs: [
        main: "readme",
        extras: [
          "README.md",
          "MENU.md",
          "TABS.md",
          "DIALOG.md",
          "TOOLTIP.md",
          "APPLICATION_INTEGRATION.md",
          "ACCORDION.md",
          "RADIO_GROUP.md",
          "CHANGELOG.md"
        ]
      ],
      description: "Contract-backed, patch-safe interaction primitives for Phoenix LiveView.",
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:plug_cowboy, "~> 2.7", only: [:dev, :test]},
      {:jason, "~> 1.4", only: [:dev, :test]},
      {:live_interaction_contracts, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "fixture/lib"]
  defp elixirc_paths(_env), do: ["lib"]

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files:
        ~w(lib mix.exs README.md MENU.md TABS.md DIALOG.md TOOLTIP.md APPLICATION_INTEGRATION.md ACCORDION.md RADIO_GROUP.md CHANGELOG.md LICENSE)
    ]
  end
end
