defmodule Mpnetwork.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Mpnetwork.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Mpnetwork.Web.Endpoint, []),
      # Start your own worker by calling: Mpnetwork.Worker.start_link(arg1, arg2, arg3)
      # worker(Mpnetwork.Worker, [arg1, arg2, arg3]),
      worker(Cachex, [:attachment_cache, [
        limit: %Cachex.Limit{
          limit: 1500,
          policy: Cachex.Policy.LRW,
          reclaim: 0.1
        }]
      ]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mpnetwork.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
