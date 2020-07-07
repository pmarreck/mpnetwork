defmodule MpnetworkWeb.UserView do
  use MpnetworkWeb, :view
  alias MpnetworkWeb.GlobalHelpers
  alias Mpnetwork.{Permissions, User}

  def is_locked?(%User{} = user) do
    user.failed_attempts > 0 && user.locked_at
  end
end
