defmodule MpnetworkWeb.LayoutView do
  use MpnetworkWeb, :view

  alias MpnetworkWeb.{BroadcastView, ListingView, AttachmentView, PageView}
  @app_name "MPWNetwork"

  def page_title(conn) do
    import Phoenix.Controller
    view = view_module(conn)
    action = action_name(conn)
    get_page_title(view, action, conn.assigns)
  end

  def get_page_title(PageView, :index, _), do: "Manhasset - Port Washington Real Estate Network"
  def get_page_title(ListingView, _, _), do: "#{@app_name} - Listing"
  def get_page_title(AttachmentView, _, _), do: "#{@app_name} - Attachments"
  def get_page_title(BroadcastView, _, _), do: "#{@app_name} - Broadcasts"
  def get_page_title(_, _, _), do: @app_name

end
