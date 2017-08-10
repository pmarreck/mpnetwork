# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :mpnetwork,
  ecto_repos: [Mpnetwork.Repo],
  max_attachment_size: 20_000_000, # 20 megabytes.
  attachment_chunk_size: 2_000_000, # default chunk length, 2MB
  attachment_chunk_timeout: 10_000, # timeout in ms per chunk, 10s
  max_attachments_per_listing: 20, # not enforced yet!
  cache_name: :attachment_cache

# Configures the endpoint
config :mpnetwork, MpnetworkWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0UYiCVV96M2bKbnZuilr1oNUY+NRJz8F07d3nWVjUOEwBHmxohBn2W4qjz+9oVUd",
  render_errors: [view: MpnetworkWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Mpnetwork.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures Swoosh (email wrapper)
config :mpnetwork, Mpnetwork.Mailer,
  adapter: Swoosh.Adapters.SparkPost,
  api_key: "391412c2902a3baaa710823b1fdfdbecd35c0373",
  endpoint: "https://api.sparkpost.com/api/v1"

# Configures Guardian
# config :guardian, Guardian,
#   allowed_algos: ["HS512"], # optional
#   verify_module: Guardian.JWT,  # optional
#   issuer: "Mpnetwork",
#   ttl: { 30, :days },
#   allowed_drift: 2000,
#   verify_issuer: true, # optional
#   secret_key: System.get_env("GUARDIAN_SECRET_KEY"),
#   serializer: MyApp.GuardianSerializer

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
  logged_out_url: "/",
  email_from_name: "Manhasset-Port Washington Board of Realtors",
  email_from_email: "board@mpwrealestateboard.network",
  opts: [:authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :invitable, :confirmable, :rememberable],
  require_current_password: true, # Current password is required when updating new password.
  reset_token_expire_days: 2,
  confirmation_token_expire_days: 5,
  allow_unconfirmed_access_for: 0,
  max_failed_login_attempts: 5,
  unlock_timeout_minutes: 15,
  unlock_token_expire_minutes: 15,
  rememberable_cookie_expire_hours: 14*24

config :coherence, Mpnetwork.Coherence.Mailer,
  adapter: Swoosh.Adapters.SparkPost,
  api_key: "391412c2902a3baaa710823b1fdfdbecd35c0373",
  endpoint: "https://api.sparkpost.com/api/v1"
# %% End Coherence Configuration %%

# Import Timber, structured logging
import_config "timber.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"