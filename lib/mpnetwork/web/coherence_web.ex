defmodule Mpnetwork.Coherence.Web do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller, except: [layout_view: 2] #, namespace: BlogPhx.Web
      use Coherence.Config
      use Timex

      import Ecto
      import Ecto.Query
      import Plug.Conn
      import Mpnetwork.Web.Router.Helpers
      import Mpnetwork.Web.Gettext
      import Coherence.ControllerHelpers

      alias Coherence.Config
      alias Coherence.ControllerHelpers, as: Helpers

      require Redirects
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/mpnetwork/web/templates/coherence"
      # Import convenience functions from controllers

      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Mpnetwork.Web.Router.Helpers
      import Mpnetwork.Web.ErrorHelpers
      import Mpnetwork.Web.Gettext
      import Mpnetwork.Coherence.ViewHelpers
      # custom global helpers
      import Mpnetwork.Web.GlobalHelpers
    end
  end
  
  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
