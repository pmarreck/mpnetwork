# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :mpnetwork,
  ecto_repos: [Mpnetwork.Repo],
  # 20 megabytes.
  max_attachment_size: 20_000_000,
  # default chunk length, 2MB
  attachment_chunk_size: 2_000_000,
  # timeout in ms per chunk, 10s
  attachment_chunk_timeout: 10_000,
  # 20-ish photos plus maybe a pdf or 2
  max_attachments_per_listing: 25,
  cache_name: :attachment_cache,
  default_cache_expiry: [months: -2] # passed directly to Timex.shift

# Configures the endpoint
config :mpnetwork, MpnetworkWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0UYiCVV96M2bKbnZuilr1oNUY+NRJz8F07d3nWVjUOEwBHmxohBn2W4qjz+9oVUd",
  render_errors: [view: MpnetworkWeb.ErrorView, accepts: ~w(html json)],
  http: [protocol_options: [max_request_line_length: 8192, max_header_value_length: 8192, idle_timeout: 90_000]],
  pubsub: [name: Mpnetwork.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures the job scheduler via Quantum
config :mpnetwork, Mpnetwork.Scheduler,
  overlap: false,
  # :utc ?
  timezone: "America/New_York",
  jobs: [
    # Runs every midnight:
    {"@daily", {Mpnetwork.Jobs, :set_expired_listings_to_exp_status, []}},
    {"@daily", {Mpnetwork.Jobs, :delete_old_cache_entries, []}}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: Mpnetwork.User,
  repo: Mpnetwork.Repo,
  module: Mpnetwork,
  web_module: MpnetworkWeb,
  router: MpnetworkWeb.Router,
  layout: {MpnetworkWeb.Coherence.LayoutView, "app.html"},
  messages_backend: MpnetworkWeb.Coherence.Messages,
  site_name: "MPWrealestateboard.network",
  logged_in_url: "/",
  logged_out_url: "/sessions/new",
  email_from_name: "Manhasset-Port Washington Board of Realtors",
  email_from_email: "no-reply@bounces.mpwrealestateboard.network",
  opts: [
    :authenticatable,
    :recoverable,
    :lockable,
    :trackable,
    :unlockable_with_token,
    :invitable,
    :rememberable
  ],
  require_current_password: false,
  reset_token_expire_days: 2,
  allow_unconfirmed_access_for: 0,
  max_failed_login_attempts: 6,
  unlock_timeout_minutes: 10,
  unlock_token_expire_minutes: 60,
  rememberable_cookie_expire_hours: 14 * 24

config :coherence, MpnetworkWeb.Coherence.Mailer,
  adapter: Swoosh.Adapters.SparkPost,
  api_key: "391412c2902a3baaa710823b1fdfdbecd35c0373",
  endpoint: "https://api.sparkpost.com/api/v1"

# %% End Coherence Configuration %%

# Configures Swoosh (email wrapper) for the mpnetwork app
config :mpnetwork, Mpnetwork.Mailer,
  adapter: Swoosh.Adapters.SparkPost,
  api_key: "391412c2902a3baaa710823b1fdfdbecd35c0373",
  endpoint: "https://api.sparkpost.com/api/v1"

# Configures Mime
config :mime, :types, %{
  "application/json" => ["json"]
}

config :mpnetwork, Mpnetwork.Repo, loggers: [Ecto.LogEntry]

# Import Timber, structured logging
# import_config "timber.exs"

# Configures ex_rated (rate limiter) used in image conversion
# Current limit is 4 images a second
config :ex_rated,
  bucket_time: 1_000,
  bucket_limit: 4

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
