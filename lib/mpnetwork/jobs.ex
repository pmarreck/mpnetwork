defmodule Mpnetwork.Jobs do
  alias Mpnetwork.{Realtor, Cache, Session}

  def set_expired_listings_to_exp_status() do
    Realtor.update_expired_listings()
  end

  def delete_old_cache_entries() do
    Cache.purge()
  end

  def delete_old_sessions() do
    Session.delete_old_sessions()
  end
end
