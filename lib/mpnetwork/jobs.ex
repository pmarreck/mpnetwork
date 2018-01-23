defmodule Mpnetwork.Jobs do

  alias Mpnetwork.Realtor

  def set_expired_listings_to_exp_status() do
    Realtor.update_expired_listings
  end

end
