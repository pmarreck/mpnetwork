use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mpnetwork, MpnetworkWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :mpnetwork, Mpnetwork.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "mpnetwork_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Mailer stub for Swoosh
config :mpnetwork, Mpnetwork.Mailer,
  adapter: Swoosh.Adapters.Test
