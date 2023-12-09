defmodule Hexdump.MixProject do
  use Mix.Project

  def project do
    [
      app: :hexdump,
      version: "0.1.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/dkuku/hexdump"
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Hexdump makes it easier to work with binary data."
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/dkuku/hexdump"}
    ]
  end
end
