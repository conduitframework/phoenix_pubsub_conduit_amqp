defmodule PhoenixPubsubConduitAmqp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :phoenix_pubsub_conduit_amqp,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: ["publish": ["hex.publish", &git_tag/1]]
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
      {:recon, "~> 2.3"}
    ]
  end

  defp git_tag(_args) do
    tag = "v" <> Mix.Project.config[:version]
    System.cmd("git", ["tag", tag])
    System.cmd("git", ["push", "origin", tag])
  end
end
