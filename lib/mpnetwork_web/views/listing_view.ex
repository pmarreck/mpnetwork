defmodule MpnetworkWeb.ListingView do
  use MpnetworkWeb, :view
  import MpnetworkWeb.GlobalHelpers
  import Mpnetwork.Listing, only: [public_client_listing_code: 1, public_agent_listing_code: 1]

  @blank_select_opt {" ", nil}
  def prepend_blank_select_opt([]) do
    [@blank_select_opt]
  end
  def prepend_blank_select_opt([_|_] = one_or_more) do
    [@blank_select_opt | one_or_more]
  end
end
