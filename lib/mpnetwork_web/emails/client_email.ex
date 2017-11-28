Code.ensure_loaded Phoenix.Swoosh

defmodule Mpnetwork.ClientEmail do
  @moduledoc false
  use Phoenix.Swoosh, view: Mpnetwork.EmailView
  import Swoosh.Email
  alias Swoosh.Email
  require Logger

  # defp site_name, do: Config.site_name(inspect Config.module)

  def send_client(email_address, name, listing, url) do
    %Email{}
    |> from(from_email())
    |> to({name, email_address})
    |> reply_to(if listing, do: {listing.user.name, listing.user.email}, else: from_email())
    |> subject("Property of Interest#{if listing, do: ": " <> listing.address, else: ""}!")
    |> render_body("listing_email.html", %{url: url, name: name, listing: listing})
  end

  # defp add_reply_to(mail) do
  #   case Coherence.Config.email_reply_to do
  #     nil              -> mail
  #     true             -> reply_to mail, from_email()
  #     address          -> reply_to mail, address
  #   end
  # end

  # defp first_name(name) do
  #   case String.split(name, " ") do
  #     [first_name | _] -> first_name
  #     _ -> name
  #   end
  # end

  defp from_email do
    case Coherence.Config.email_from do
      nil ->
        Logger.error ~s|Need to configure :coherence, :email_from_name, "Name", and :email_from_email, "me@example.com"|
        nil
      {name, email} = email_tuple ->
        if is_nil(name) or is_nil(email) do
          Logger.error ~s|Need to configure :coherence, :email_from_name, "Name", and :email_from_email, "me@example.com"|
          nil
        else
          email_tuple
        end
    end
  end
end
