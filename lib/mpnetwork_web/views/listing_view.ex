defmodule MpnetworkWeb.ListingView do
  use MpnetworkWeb, :view
  import MpnetworkWeb.GlobalHelpers
  import Mpnetwork.Listing, only: [public_client_full_code: 1, public_broker_full_code: 1, public_customer_full_code: 1]
end
