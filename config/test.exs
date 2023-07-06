import Config

# General application configuration
config :mpnetwork, cache_name: :test_attachment_cache

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mpnetwork, MpnetworkWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Configure your database
config :mpnetwork, Mpnetwork.Repo,
  adapter: Ecto.Adapters.Postgres,
  # for some reason, `mix test` errors unless this key is here, regardless of :url key presence
  database: "mpnetwork_test",
  url: System.fetch_env!("TEST_DATABASE_URL"),
  pool: Ecto.Adapters.SQL.Sandbox

# Mailer stub for Swoosh
config :mpnetwork, Mpnetwork.Mailer, adapter: Swoosh.Adapters.Test

config :coherence, MpnetworkWeb.Coherence.Mailer, adapter: Swoosh.Adapters.Test

# Change password hash algorithm to a no-op to make tests faster
config :coherence, :password_hashing_alg, Mpnetwork.Utils.NoopHash

# Disable Oban job runners in test
config :mpnetwork, Oban, crontab: false, queues: false, plugins: false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
