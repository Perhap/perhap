defmodule Shopping.Mixfile do
  use Mix.Project

  def project do
    [
      app: :shopping,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:perhap],
      extra_applications: [:logger],
      mod: {Shopping, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:perhap, path: "~/Development/Perhap/perhap"},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end
end
