defmodule Mpnetwork.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mpnetwork,
      version: String.trim(File.read!("VERSION")),
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: (Mix.compilers() -- [:gettext]),
      # compilers: [:rustler, :phoenix] ++ Mix.compilers(),
      # rustler_crates: [
      #   lvips: [
      #     path: "native/lvips",
      #     mode: (if Mix.env() == :prod, do: :release, else: :debug)
      #   ]
      # ],
      xref: [exclude: [EEx, Toml]],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, test_js: :test],
      dialyzer: [plt_add_deps: :transitive],
      package: package()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      # applications: [:coherence],
      mod: {Mpnetwork.Application, []},
      extra_applications: [:coherence, :logger, :runtime_tools, :ex_rated, :os_mon, :telemetry, :crypto]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # {:distillery, "~> 2.1"},
      {:cowboy, "~> 2.5"},
      {:plug_cowboy, "~> 2.2"},
      {:phoenix, "~> 1.6"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_view, "~> 0.17"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:gettext, "~> 0.13"},
      {:excellent_migrations, "~> 0.1.2", only: [:dev, :test], runtime: false},
      # Keep checking this https://github.com/smpallen99/coherence/pull/398 to see if the conspicuously absent fucker ever actually merges it
      # {:coherence, git: "https://github.com/johannesE/coherence", branch: "#394"},
      # {:coherence, "~> 0.5"},
      # I ended up forking it in order to update all its deps, make all its tests pass again and silence most warnings.
      {:coherence, git: "https://github.com/pmarreck/coherence", commit: "aa0ef8403197dfd262863f4b0e592122a1a3e525"},
      {:ex_doc, "~> 0.14", only: :dev},
      {:tzdata, "~> 1.1"},
      {:timex, "~> 3.7"},
      # moved dep to git commit to squash big dep warning on elixir 1.8:
      # https://github.com/bitwalker/timex/commit/f59156b59552ca113c3d4b978d3773997971c67c
      # {:timex, git: "https://github.com/bitwalker/timex.git", commit: "f59156b59552ca113c3d4b978d3773997971c67c", override: true},
      {:number, "~> 1.0"},
      {:ex_image_info, "~> 0.2"},
      # provides `mix eliver.bump` for hot prod upgrades
      {:eliver, "~> 2.0"},
      # {:cachex, "~> 2.1"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.7", only: :test},
      {:swoosh, "~> 1.3.4"},
      {:phoenix_swoosh, "~> 0.3"},
      # want to replace with another solution asap lol. https://imagetragick.com/
      # {:mogrify, "~> 0.8"}, # BITCH, BEGONE
      # replacement for the above, hopefully!
      # {:resamplex, "~> 0.1.0"},
      # for easily working with tempfiles
      {:briefly, "~> 0.3"},
      # {:ex_crypto, "~> 0.10"}, # removed because not being updated yet for OTP24
      {:ecto_sql, "~> 3.5"},
      {:ecto_psql_extras, "~> 0.2"},
      # {:ecto_enum, "~> 1.0"}, # still has a bug. waiting on fix. forked, fixed, and PR'd in meantime:
      # {:ecto_enum, git: "https://github.com/pmarreck/ecto_enum.git", commit: "f7b65534e11545d23c626c655ce26c73e43117f0"},
      # {:ecto_enum, "~> 1.4"},
      # Repinned to a commit on 20200422 due to mix dependency fixes that did not result in a version bump:
      {:ecto_enum,
       git: "https://github.com/gjaldon/ecto_enum.git",
       commit: "ab13face20729deb0cb2f325dc052fd6fd05c26a"},
      {:html_sanitize_ex, "~> 1.4"},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:quantum, ">= 2.2.5"},
      {:ex_rated, "~> 1.3"}, # this is now 2.0 and API may have changed, but it has good improvements
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      # note: may not build on OTP23:
      # second note: had a bitch-ass time trying to get lz4_erl to build on my Docker image and failed,
      # so I ripped it out since it was currently only being used for session data.
      # Perhaps revisit CompressedTerm with a different library in the future, perhaps zstd, but
      # definitely something that uses Rust preferably (via Rustler) as the NIF code.
      # LASTLY: I've since learned that Postgres already does some lz4 compression of binary data if it's above a certain size
      # {:lz4, "~> 0.2.4", hex: :lz4_erl},
      # @vanvoljg on Elixir Slack #general channel @ 5/27/20 8:21 PM:
      # As an update on my end, I was able to get erlang_lz4 to compile with OTP23 by modifying the makefile.
      # Removing -lerl_interface (which was deprecated in OTP23) from the libs allows it to compile.
      # I have no idea if it generates correct code, but it compiles.
      # in `./deps/lz4/c_src/Makefile`, on line 36: `LDLIBS += -L $(ERL_INTERFACE_LIB_DIR) -lei`
      # @tsloughter not long after said...
      # Suggest using the git master version since it uses the rebar3 plugin that works on OTP-23
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      # When upgrading Oban, MAKE SURE YOU DON'T HAVE TO MANUALLY RUN SOME MIGRATIONS!
      # https://github.com/sorentwo/oban/blob/master/CHANGELOG.md
      {:oban, "~> 2.10"},
      # for-pay deps:
      {:oban_web, "~> 2.9", repo: "oban"},
      {:oban_pro, "~> 0.8", repo: "oban"},
      {:logflare_logger_backend, "~> 0.11"},
      {:remote_ip, "~> 0.2.1"},
      {:ua_inspector, "~> 2.2"},
      {:enquirer, "~> 0.1.0"},
      # running hog-wild with rust here, since it's still quite a moving target
      # ... hey, my test suite includes image manips, so...!
      # {:rustler, git: "https://github.com/rusterlium/rustler.git", branch: "master", override: true},
      # EDIT 6/7/2021: Disabling Rustler for now as a dep
      # {:rustler, "~> 0.22.0-rc.1", override: true},
      # {:elxvips, git: "https://github.com/pmarreck/elxvips.git", branch: "master"},
      # elxvips' ENTIRE CODEBASE basically assumes you are only resizing, so adding rotation from vips was unnecessarily difficult
      # EDIT 6/7/2021: I'm REMOVING elxvips as the Rust toolchain dependency is too fragile yet and keeps breaking in Docker and also with buildpacks
      # So now I'm using (dun dun dunnnn)...
      {:vix, "~> 0.12.0"}, # which doesn't let you work directly with binary data... YET. Sigh. Tempfiles it is.
      # I forked ex_png and added a way to work directly with png binary data instead of only through files.
      # As of today (4/27/2021) he hasn't accepted the PR yet...
      {:ex_png, git: "https://github.com/pmarreck/ex_png.git", branch: "main", only: :test},
    ]
  end

  def package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      licenses: ["EUPL-1.2"],
      maintainers: ["Peter Marreck"],
      links: %{"GitHub" => "https://github.com/pmarreck/mpnetwork"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
