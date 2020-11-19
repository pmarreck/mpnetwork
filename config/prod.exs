use Mix.Config

# For production, we often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# MpnetworkWeb.Endpoint.load_from_system_env/1 dynamically.
# Any dynamic configuration should be moved to such function.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# Finally, we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the mix phoenix.digest task
# which you typically run after static files are built.
config :mpnetwork, MpnetworkWeb.Endpoint,
  load_from_system_env: true,
  http: [
    port: {:system, "PORT"},
    protocol_options: [
      max_request_line_length: 8192,
      max_header_value_length: 8192,
      idle_timeout: 90_000
    ]
  ],
  root: ".",
  server: true,
  url: [scheme: "https", host: "${FQDN}", port: 443],
  static_url: [scheme: "https", host: "${STATIC_URL}", port: 443],
  force_ssl: [hsts: true, rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: "${SECRET_KEY_BASE}"

# Do not print debug messages in production.
# Point to Logflare.
config :logger, level: :info, backends: [:console, LogflareLogger.HttpBackend]

# Logflare config
config :logflare_logger_backend,
  url: "https://api.logflare.app", # https://api.logflare.app is configured by default and you can set your own url
  level: :info, # Default LogflareLogger level is :info. Note that log messages are filtered by the :logger application first
  api_key: System.fetch_env!("LOGFLARE_API_KEY"),
  source_id: System.fetch_env!("LOGFLARE_DRAIN_ID"),
  flush_interval: 1_000, # minimum time in ms before a log batch is sent to the server ",
  max_batch_size: 50 # maximum number of events before a log batch is sent to the server

# Disable Phoenix logger in prod
# config :phoenix, :logger, false

# config :logger, :console, format: "[$level] $message\n"

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :mpnetwork, MpnetworkWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :mpnetwork, MpnetworkWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :mpnetwork, MpnetworkWeb.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.

# Commented out due to Heroku config
# import_config "prod.secret.exs"

# Database config
# Configure your database
# Note that {:system, "DATABASE_URL"} is deprecated so the db url is now set in the init callback in Mpnetwork.Repo

config :mpnetwork, Mpnetwork.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.fetch_env!("DATABASE_URL"),
  # limit in google cloud postgres is 100. Note that I got a "too many connections error" at 60.
  # Max is 30 but 2 replicas might be up at once potentially, plus Google, plus my client, plus migrations etc...
  pool_size: 28,
  # https://hexdocs.pm/db_connection/DBConnection.html#start_link/2
  queue_target: 300,
  queue_interval: 2000,
  ssl: true

# Guardian
# config :guardian, Guardian,
#   secret_key: System.get_env("GUARDIAN_SECRET_KEY")

config :phoenix, :serve_endpoints, true
