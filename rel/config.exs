# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
    # This sets the default release built by `mix distillery.release`
    default_release: :default,
    # This sets the default environment used by `mix distillery.release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"S$mcKp~5hKkBNn:lwbT3x?hN&3o?~P[xfm_Fb3dFBp,}P4efNK%zGt2|trO=F:$q"
end

environment :staging do
  set include_erts: true
  set include_src: false
  set cookie: :"K3rNr+Rf305oOBrXHcE2rYMmIxZEOG1Dp1CnHUeUltCGwAWy/HwBs8eb7oWgSYwt"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"B8ZQgmmb&FehGImXOA;tF>AQ<DKkTSt.7eB}[F|[90{PMR9evUweg%tU!!OI[s~s"
  set vm_args: "rel/vm.args"
  set pre_start_hooks: "rel/commands/prestart_hooks"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :mpnetwork do
  set version: current_version(:mpnetwork)
  set commands: [
    migrate: "rel/commands/prestart_hooks/migrate.sh",
    seed: "rel/commands/seed.sh",
  ]
  set applications: [
    :runtime_tools
  ]
end

