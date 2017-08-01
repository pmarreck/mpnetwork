defmodule MpnetworkWeb.Router do
  use MpnetworkWeb, :router
  use Coherence.Router

  def create_timber_user_context(conn, _opts) do
    if conn.assigns[:current_user] do
      user = conn.assigns.current_user
      %Timber.Contexts.UserContext{id: user.id, name: user.name, email: user.email}
      |> Timber.add_context()
    end
    conn
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true
    plug :create_timber_user_context
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser
    coherence_routes()
  end

  scope "/" do
    pipe_through :protected
    coherence_routes :protected
  end


  scope "/", MpnetworkWeb do
    pipe_through :protected
    # Add protected routes below
    get "/", PageController, :index # (even the landing page requires login)

    get "/listings/:id/email_listing", ListingController, :email_listing, as: :email_listing
    post "/listings/:id/send_email", ListingController, :send_email, as: :email_listing
    resources "/broadcasts", BroadcastController
    resources "/listings", ListingController
    resources "/attachments", AttachmentController, except: [:show]
  end
  
  scope "/", MpnetworkWeb do
    pipe_through :browser # Use the default browser stack
    # Add public routes below
    get "/client_listing/:id/:sig", ListingController, :client_listing, as: :public_client_listing
    get "/agent_listing/:id/:sig", ListingController, :agent_listing, as: :public_agent_listing
    # Image (and all) attachments are currently unauthenticated due to the need to make them available
    # in public links to listings... could this end up being a security problem due to autoincrementing IDs?
    resources "/attachments", AttachmentController, only: [:show]
  end
  
  # custom dev-only route to view local mailbox
  if Mix.env == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview, [base_path: "/dev/mailbox"]
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MpnetworkWeb do
  #   pipe_through :api
  # end
end
