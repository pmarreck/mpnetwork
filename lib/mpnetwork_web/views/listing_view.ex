defmodule MpnetworkWeb.ListingView do
  use MpnetworkWeb, :view
  import MpnetworkWeb.GlobalHelpers
  import Mpnetwork.Listing, only: [public_client_listing_code: 1, public_agent_listing_code: 1]
end
