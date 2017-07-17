defmodule Perhap.Mixfile do
  use Mix.Project
  require Logger

  @version "0.0.1-dev"
  {:ok, system_version} = Version.parse(System.version)
  @elixir_version "#{system_version.major}.#{system_version.minor}.#{system_version.patch}"

  def version do
    @version
  end

  def project do
    Logger.debug("Perhap #{@version} using Elixir #{@elixir_version}")
    [app: :perhap,
     version: @version,
     description: description(),
     package: package(),
     elixir: "~> 1.4",
     build_per_environment: false,
     consolidate_protocols: Mix.env != :test,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :cowboy, :plug, :gproc]]
  end

  defp deps do
    [{:dialyxir, "~> 0.5", only: :dev, runtime: false},
     {:ex_doc, "~> 0.15.0", only: :dev, runtime: false},
     {:cowboy, "~> 1.0.0"},
     {:plug, "~> 1.0"},
     {:gproc, "~> 0.6.1"},
     {:json, "~> 1.0"},
     {:gen_stage, "~> 0.11.0"}]
     # {:ranch, github: "ninenines/ranch", ref: "1.4.0", override: true},
     # {:gun, github: "ninenines/gun", ref: "1.0.0-pre.3", runtime: false},
     # {:snappy, github: "fdmanana/snappy-erlang-nif"},
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
end
