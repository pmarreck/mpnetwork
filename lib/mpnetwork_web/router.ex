defmodule MpnetworkWeb.Router do
  use MpnetworkWeb, :router
  use Coherence.Router
  import Phoenix.LiveDashboard.Router
  import Oban.Web.Router
  alias Mpnetwork.Repo
  require Logger
  require Phoenix.Logger
  require UAInspector

  # def create_timber_user_context(conn, _opts) do
  #   if conn.assigns[:current_user] do
  #     user = conn.assigns.current_user

  #     %Timber.Contexts.UserContext{id: user.id, name: user.name, email: user.email}
  #     |> Timber.add_context()
  #   end

  #   conn
  # end

  @user_schema Application.get_env(:coherence, :user_schema)
  @id_key Application.get_env(:coherence, :schema_key)

  defp safe_map_from_struct(nil), do: %{}
  defp safe_map_from_struct(:unknown), do: %{}
  defp safe_map_from_struct(struct) when is_map(struct) do
    Map.from_struct(struct)
  end
  defp safe_map_from_struct(_), do: %{}

  defp blank_is_nil(""), do: nil
  defp blank_is_nil(nil), do: nil
  defp blank_is_nil(anything_else), do: anything_else

  defp collect_request_data_for_logging(conn, _) do
    Plug.Conn.register_before_send(conn, fn conn ->
      user_agent = case get_req_header(conn, "user-agent") do
        [user_agent] -> UAInspector.parse(user_agent)
        _ -> nil
      end
      user_agent = case user_agent do
        %UAInspector.Result{} -> %{human: %{client: safe_map_from_struct(user_agent.client), device: safe_map_from_struct(user_agent.device), OS: safe_map_from_struct(user_agent.os)}, bot: %{}}
        %UAInspector.Result.Bot{} -> %{human: %{}, bot: %{category: user_agent.category, name: user_agent.name, producer: safe_map_from_struct(user_agent.producer), url: user_agent.url}}
        _ -> %{human: %{}, bot: %{}}
      end
      LogflareLogger.context(response: %{status_code: conn.status}, user_agent: user_agent)
      # IO.inspect(conn, limit: :infinity, printable_limit: :infinity, pretty: true)
      # if Mix.env() == :dev do
      #   Logger.debug(context: LogflareLogger.context())
      # end
      Logger.info([method: conn.method, path: conn.request_path, params: Phoenix.Logger.filter_values(conn.params), from: conn.remote_ip])
      conn
    end)
  end

  defp ensure_not_downtime(conn, _) do
    # example system env var to set:
    # DOWNTIME_END_AT="2021-01-06T02:30 America/New_York"
    # gigalixir example: gigalixir config:set DOWNTIME_END_AT="2021-01-06T02:30 America/New_York"
    # then, gigalixir config:unset DOWNTIME_END_AT, when finished
    # Note that this value MUST have ONLY ONE space in it, separating the datetime from the timezone, both ISO 8601.
    if blank_is_nil(System.get_env("DOWNTIME_END_AT")) && conn.path_info() != ["downtime"] do
      conn
      |> Plug.Conn.resp(:found, "")
      |> Plug.Conn.put_resp_header("location", "/downtime")
    else
      conn
    end
  end

  pipeline :browser do
    plug(RemoteIp)
    plug(:collect_request_data_for_logging)
    plug(:accepts, ["html"])
    plug(:ensure_not_downtime)
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)

    plug(Coherence.Authentication.Session,
      store: Coherence.CredentialStore.Session,
      db_model: @user_schema,
      id_key: @id_key
    )
  end

  defp create_session_contexts(conn, _) do
    # create "office" context
    u = conn.assigns.current_user |> Repo.preload(:broker)
    conn = Plug.Conn.assign(conn, :current_office, u.broker)
    # create logflare user context
    LogflareLogger.context(user: %{id: u.id}, office: %{id: u.broker.id})
    conn
  end

  pipeline :protected do
    plug(RemoteIp)
    plug(:collect_request_data_for_logging)
    plug(:accepts, ["html", "json"])
    plug(:ensure_not_downtime)
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)

    plug(Coherence.Authentication.Session,
      protected: true,
      store: Coherence.CredentialStore.Session,
      db_model: @user_schema,
      id_key: @id_key
    )

    plug(:create_session_contexts)
    plug(:collect_request_data_for_logging)
  end

  defp admin_check(conn, _) do
    # note that this assumes the session's already been fetched in its pipeline, or it will fail
    if conn.assigns.current_user.role_id > 2 do
      send_resp(conn, 405, "Not allowed")
    else
      conn
    end
  end

  pipeline :admin_protected do
    plug(:admin_check)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/" do
    pipe_through(:browser)
    coherence_routes()
  end

  scope "/" do
    pipe_through(:protected)
    coherence_routes(:protected)
  end

  scope "/", MpnetworkWeb do
    pipe_through([:protected, :admin_protected])
    resources("/offices", OfficeController)
    get("/users/locked_users", UserController, :locked_users)
    post("/users/:id/unlock_user", UserController, :unlock_user)
    resources("/users", UserController)
    live_dashboard("/dashboard", metrics: MpnetworkWeb.Telemetry, env_keys: ["SOURCE_VERSION"], ecto_repos: [Mpnetwork.Repo], allow_destructive_actions: true)
    oban_dashboard "/jobs"
  end

  scope "/", MpnetworkWeb do
    pipe_through(:protected)
    # Add protected routes below
    # (even the landing page requires login)
    get("/", PageController, :index)

    get("/listings/:id/email_listing", ListingController, :email_listing, as: :email_listing)
    post("/listings/:id/send_email", ListingController, :send_email, as: :email_listing)
    get("/listings/inspections", ListingController, :inspection_sheet, as: :upcoming_inspections)
    resources("/broadcasts", BroadcastController)
    resources("/listings", ListingController)
    # couldn't get Clone to work otherwise
    put("/listings", ListingController, :create)
    post("/attachments/:id/rotate_left", AttachmentController, :rotate_left)
    post("/attachments/:id/rotate_right", AttachmentController, :rotate_right)
    resources("/attachments", AttachmentController)
    resources("/profiles", ProfileController, as: :profile, only: [:edit, :update, :show])
    get("/search", ListingController, :search, as: :search)
    get("/search_help", ListingController, :search_help, as: :search_help)

    # solves bug with multiple login attempts trying to redirect back to /sessions after success due to referer changing
    get("/sessions", PageController, :bare_session_redirect)
  end

  scope "/", MpnetworkWeb do
    # Use the default browser stack
    pipe_through(:browser)
    # Add public routes below
    get("/client_full/:id", ListingController, :client_full, as: :public_client_full)
    get("/broker_full/:id", ListingController, :broker_full, as: :public_broker_full)
    get("/customer_full/:id", ListingController, :customer_full, as: :public_customer_full)
    get("/attachments/show_public/:id", AttachmentController, :show_public)
    get("/downtime", PageController, :downtime)
  end

  # custom dev-only route to view local mailbox
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through(:browser)

      forward("/mailbox", Plug.Swoosh.MailboxPreview, base_path: "/dev/mailbox")
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MpnetworkWeb do
  #   pipe_through :api
  # end
end
