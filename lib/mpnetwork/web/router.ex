defmodule Mpnetwork.Web.Router do
  use Mpnetwork.Web, :router
  use Coherence.Router

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

  scope "/", Mpnetwork.Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    # Add public routes below
  end

  scope "/", Mpnetwork.Web do
    pipe_through :protected
    # Add protected routes below
    resources "/broadcasts", BroadcastController
    resources "/listings", ListingController
    resources "/attachments", AttachmentController
  end

  # Other scopes may use custom stacks.
  # scope "/api", Mpnetwork.Web do
  #   pipe_through :api
  # end
end
