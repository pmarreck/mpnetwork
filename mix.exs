defmodule Mpnetwork.Mixfile do
  use Mix.Project

  def project do
    [app: :mpnetwork,
     version: String.trim(File.read!("VERSION")),
     elixir: "~> 1.5.1",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test],
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      # applications: [:coherence],
      mod: {Mpnetwork.Application, []},
      extra_applications: [:coherence, :logger, :runtime_tools],
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:distillery, "~> 1.4.0"},
      {:phoenix, "~> 1.3", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.1", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:coherence, github: "smpallen99/coherence", branch: "master"},
      {:ex_doc, "~> 0.14", only: :dev},
      {:timex, "~> 3.1"},
      {:number, "~> 0.5"},
      {:timber, "~> 2.6"},
      {:ex_image_info, "~> 0.1.1"},
      {:eliver, "~> 2.0"}, # provides `mix eliver.bump` for hot prod upgrades
      {:cachex, "~> 2.1"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.7", only: :test},
      {:swoosh, "~> 0.8"},
      # phoenix_swoosh newer version already included by Coherence (and conflicts with this)
      # {:phoenix_swoosh, git: "https://github.com/vircung/phoenix_swoosh.git", branch: "phx-1.3"},
      {:mogrify, "~> 0.5.4"}, # want to replace with another solution asap lol. https://imagetragick.com/
      {:briefly, "~> 0.3"}, # for easily working with tempfiles
      {:ex_crypto, "~> 0.4", override: true},
      {:ecto, "~> 2.2.6", override: true},
      # {:ecto_enum, "~> 1.0"}, # still has a bug. waiting on fix. forked, fixed, and PR'd in meantime:
      {:ecto_enum, git: "https://github.com/pmarreck/ecto_enum.git", branch: "master"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
