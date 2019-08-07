defmodule MpnetworkWeb.Router do
  use MpnetworkWeb, :router
  use Coherence.Router
  alias Mpnetwork.Repo

  # def create_timber_user_context(conn, _opts) do
  #   if conn.assigns[:current_user] do
  #     user = conn.assigns.current_user

  #     %Timber.Contexts.UserContext{id: user.id, name: user.name, email: user.email}
  #     |> Timber.add_context()
  #   end

  #   conn
  # end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Coherence.Authentication.Session)
  end

  defp create_office_context(conn, _) do
    u = conn.assigns.current_user |> Repo.preload(:broker)
    Plug.Conn.assign(conn, :current_office, u.broker)
  end

  pipeline :protected do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Coherence.Authentication.Session, protected: true)
    plug(:create_office_context)
    # plug(:create_timber_user_context)
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
    resources("/users", UserController)
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
    put("/listings", ListingController, :create) # couldn't get Clone to work otherwise
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
