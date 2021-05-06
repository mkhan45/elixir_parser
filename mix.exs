defmodule ElixirParse.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_parse,
      version: "0.1.0",
      elixir: "~> 1.11",
      escript: escript(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def escript, do: [main_module: Main]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
