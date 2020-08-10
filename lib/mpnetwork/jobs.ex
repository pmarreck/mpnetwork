defmodule Mpnetwork.Jobs do
  alias Mpnetwork.{Realtor, Cache, Session, UserEmail}

  def set_expired_listings_to_exp_status() do
    Realtor.update_expired_listings()
  end

  def delete_old_cache_entries() do
    Cache.purge()
  end

  def delete_old_sessions() do
    Session.delete_old_sessions()
  end

  def set_cs_listings_to_tom() do
    Realtor.set_cs_listings_to_tom()
  end

  def notify_realtor_cs_listing_about_to_expire_to_tom() do
    Realtor.get_cs_listings_with_omd_on_today()
    |> Enum.each(fn listing ->
      body_preamble = "Hello #{listing.user.name}! Please click here and assign this listing a status of either NEW or FS before midnight tonight, or it will be automatically put into Temporarily Off Market (TOM): "
      UserEmail.send_user_regarding_listing(
        listing.user,
        listing,
        "[MPWREB] Warning: A \"Coming Soon\" listing you own (#{listing.address}) has not been moved to NEW or FS and will be automatically TOM at midnight tonight!",
        "<html><body>" <> body_preamble <> "<a href='@listing_link_placeholder'>@listing_link_placeholder</a>" <> "</body></html>",
        body_preamble <> "@listing_link_placeholder",
        "notify_user_of_impending_omd_expiry"
      )
    end)
  end

end
