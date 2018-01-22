defmodule PhoenixPubsubConduitAmqp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :phoenix_pubsub_conduit_amqp,
      version: "0.1.0",
      elixir: "~> 1.5",
      description: "A phoenix pubsub adapter that uses conduit and AMQP",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "PhoenixPubsubConduitAMQP",
      source_url: "https://github.com/conduitframework/phoenix_pubsub_conduit_amqp",
      homepage_url: "https://hexdocs.pm/phoenix_pubsub_conduit_amqp",
      docs: docs(),

      # Package
      description: "AMQP adapter for Conduit.",
      package: package(),

      aliases: ["publish": ["hex.publish", &git_tag/1]]
    ]
  end

  defp package do
    [
      name: :phoenix_pubsub_conduit_amqp,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Allen Madsen"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/conduitframework/phoenix_pubsub_conduit_amqp",
        "Docs" => "https://hexdocs.pm/phoenix_pubsub_conduit_amqp"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      project: "Phoenix.Pubsub.ConduitAMQP",
      extra_section: "Guides",
      extras: ["README.md"],
      assets: ["assets"]
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
      {:phoenix_pubsub, "~> 1.0"},
      {:conduit_amqp, "~> 0.4.3"},
      {:recon, "~> 2.3"},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp git_tag(_args) do
    tag = "v" <> Mix.Project.config[:version]
    System.cmd("git", ["tag", tag])
    System.cmd("git", ["push", "origin", tag])
  end
end
