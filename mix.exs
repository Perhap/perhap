defmodule Perhap.Mixfile do
  use Mix.Project
  require Logger

  @version "0.0.2-dev"

  def version do
    @version
  end

  def project do
    [app: :perhap,
     version: @version,
     description: description(),
     package: package(),
     elixir: "~> 1.9",
     build_per_environment: false,
     consolidate_protocols: Mix.env != :test,
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     dialyzer: dialyzer_options()
    ]
  end

  def application do
    [applications: [:logger, :cowboy, :libcluster, :swarm]]
  end

  defp deps do
    [{:poison, "~> 3.1"},
     {:uuid, github: "okeuday/uuid"},
     {:cowlib, github: "ninenines/cowlib", ref: "2.8.0", override: true},
     {:gun, github: "ninenines/gun", runtime: false},
     {:cowboy, github: "ninenines/cowboy", ref: "2.7.0"},
     {:libcluster, "~> 3.1.1"},
     {:swarm, "~> 3.4.0"},
     {:dialyxir, "~> 0.5", only: :dev, runtime: false},
     {:ex_doc, "~> 0.15.0", only: :dev, runtime: false}]
  end

  defp description do
    """
    A purely functional rDDD framework.
    """
  end

  defp package do
    [maintainers: ["Rob Martin (@version2beta)"],
     licenses: ["BSD 3 clause"],
     links: %{"GitHub" => "https://github.com/Perhap/perhap"},
     files: ~w(mix.exs README.md CHANGELOG.md lib)]
  end

  defp elixirc_paths(:test), do: ["lib","test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer_options(), do: [plt_add_deps: :apps_direct, ignore_warnings: "dialyzer.ignore-warnings"]
end
