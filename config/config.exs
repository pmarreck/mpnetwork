# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :mpnetwork,
  ecto_repos: [Mpnetwork.Repo]

# Configures the endpoint
config :mpnetwork, Mpnetwork.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0UYiCVV96M2bKbnZuilr1oNUY+NRJz8F07d3nWVjUOEwBHmxohBn2W4qjz+9oVUd",
  render_errors: [view: Mpnetwork.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Mpnetwork.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
