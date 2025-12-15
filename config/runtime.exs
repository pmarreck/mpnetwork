import Config

endpoint_config = Application.get_env(:mpnetwork, MpnetworkWeb.Endpoint, [])

if endpoint_config[:load_from_system_env] do
  port =
    System.get_env("PORT", "4000")
    |> String.to_integer()

  host = System.get_env("FQDN") || "localhost"
  static_host = System.get_env("STATIC_URL") || host

  url =
    endpoint_config
    |> Keyword.get(:url, [])
    |> Keyword.put(:host, host)

  static_url =
    endpoint_config
    |> Keyword.get(:static_url, [])
    |> Keyword.put(:host, static_host)

  config :mpnetwork, MpnetworkWeb.Endpoint,
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    url: url,
    static_url: static_url
end

