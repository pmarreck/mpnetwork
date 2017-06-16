defmodule Mpnetwork.Web.Router do
  use Mpnetwork.Web, :router
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

  # scope "/", Mpnetwork.Web do
  #   pipe_through :browser # Use the default browser stack
  #   # Add public routes below
  # end

  scope "/", Mpnetwork.Web do
    pipe_through :protected
    # Add protected routes below
    get "/", PageController, :index # (even the landing page requires login)

    resources "/broadcasts", BroadcastController
    resources "/listings", ListingController
    resources "/attachments", AttachmentController
  end

  # Other scopes may use custom stacks.
  # scope "/api", Mpnetwork.Web do
  #   pipe_through :api
  # end
end
