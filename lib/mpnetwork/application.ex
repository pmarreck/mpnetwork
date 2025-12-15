defmodule Mpnetwork.Application do
  @moduledoc false
  use Application

  alias Mpnetwork.{Repo, Scheduler}
  alias MpnetworkWeb.{Telemetry, Endpoint}
  require UAInspector
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Mpnetwork.PubSub},
      # Start the Ecto repository
      Repo,
      # Start telemetry for Phoenix LiveDashboard
      Telemetry,
      # Start the endpoint when the application starts
      # supervisor(MpnetworkWeb.Endpoint, []),
      Endpoint,
      # Start your own worker by calling: Mpnetwork.Worker.start_link(arg1, arg2, arg3)
      # worker(Mpnetwork.Worker, [arg1, arg2, arg3]),
      # worker(Cachex, [
      #   Application.get_env(:mpnetwork, :cache_name),
      #   [
      #     limit: %Cachex.Limit{
      #       # bumped after implementation of app-cached thumbnails of arbitrary size
      #       limit: 5000,
      #       policy: Cachex.Policy.LRW,
      #       reclaim: 0.1
      #     }
      #   ]
      # ]),
      # Quantum Scheduler
      Scheduler,
      # Oban job runner
      {Oban, oban_config()}
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mpnetwork.Supervisor]

    sl_return = Supervisor.start_link(children, opts)
    # try to ensure the UAInspector parser is ready to go
    if UAInspector.ready? do
      Logger.info("UAInspector is ready to parse user-agents!")
      sl_return
    else
      Logger.error("UAInspector was NOT ready to parse user-agents!")
      UAInspector.Downloader.download()
      UAInspector.reload(async: false)
      true = UAInspector.ready?
      Logger.info("UAInspector is once again ready to parse user-agents.")
      sl_return
    end
  end

  # Conditionally disable crontab, queues, or plugins here.
  defp oban_config() do
    config = Application.get_env(:mpnetwork, Oban, [])

    config
    |> maybe_fallback_engine()
    |> maybe_filter_plugins()
  end

  defp maybe_fallback_engine(config) do
    case Keyword.get(config, :engine) do
      Oban.Pro.Queue.SmartEngine ->
        if Code.ensure_loaded?(Oban.Pro.Queue.SmartEngine) do
          config
        else
          Keyword.put(config, :engine, Oban.Engines.Basic)
        end

      _ ->
        config
    end
  end

  defp maybe_filter_plugins(config) do
    case Keyword.get(config, :plugins) do
      false ->
        config

      nil ->
        config

      plugins when is_list(plugins) ->
        filtered =
          Enum.filter(plugins, fn
            plugin when is_atom(plugin) ->
              Code.ensure_loaded?(plugin)

            {plugin, _opts} when is_atom(plugin) ->
              Code.ensure_loaded?(plugin)

            other ->
              other
          end)

        Keyword.put(config, :plugins, filtered)
    end
  end

end
