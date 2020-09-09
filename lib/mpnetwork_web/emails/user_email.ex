Code.ensure_loaded(Phoenix.Swoosh)

defmodule Mpnetwork.UserEmail do
  @moduledoc false
  use Phoenix.Swoosh, view: Mpnetwork.EmailView, layout: {MpnetworkWeb.EmailView, :email}
  # alias MpnetworkWeb.EmailView
  import Swoosh.Email
  alias Swoosh.Email
  alias Mpnetwork.Mailer
  alias MpnetworkWeb.Endpoint
  alias MpnetworkWeb.Router.Helpers, as: Routes
  require Logger

  # note: should be tested. and the data composition/preparation should be separated from the actual delivery.
  # I should know better, but there's an outstanding bug and I'm low on time
  # If this is future-me reading this, just do it, sincerely, past-me
  def send_user_regarding_listing(user, listing, subject, htmlbody, textbody, type \\ "notify_user_of_impending_omd_expiry") do
    name = user.name
    email_address = user.email
    url = Routes.listing_url(Endpoint, :show, listing)
    htmlbody = interpolate_placeholder_values(htmlbody, %{name: name, url: url}, "User")
    textbody = interpolate_placeholder_values(textbody, %{name: name, url: url}, "User")

    fr = from_email()

    email =
      %Email{}
      |> from(fr)
      |> to({name, email_address})
      |> reply_to(fr)
      |> subject(subject)
    email = if htmlbody do
      html_body(email, htmlbody)
    else
      email
    end
    email = if textbody do
      text_body(email, textbody)
    else
      email
    end

    email_rendered = case type do
      "new_listing_notif" ->
        render_body(email, "listing_email_expanded.html", %{listing_url: url, listing: listing, attachments: listing.attachments, broker: listing.broker, agent: listing.user, co_agent: listing.colisting_agent})
      _ ->
        render_body(email, :listing_email)
    end

    email_delivered = email_rendered
      |> deliver_and_log(type, listing, name, email_address)

    # This is sort of the philosophy of "always return some meaningful data from a function even if it's not captured by the caller"
    {status, results} = email_delivered
    {status, {email, email_rendered, results}}
  end

  defp deliver_and_log(email, type, listing, name, email_address) do
    delivery = Mailer.deliver(email)
    case delivery do
      {:ok, results} ->
        Logger.info(
          "SUCCESS: Sent listing id #{listing.id} of type #{type} to #{name} at #{email_address}, result: #{inspect(results)}"
        )

      {:error, :timeout} ->
        Logger.error(
          "ERROR: TIMED OUT emailing listing id #{listing.id} of type #{type} to #{name} at #{email_address}"
        )

      {:error, {httpcode, %{"errors" => errors}}}
      when is_integer(httpcode) and is_list(errors) ->
        Logger.error("ERROR: HTTP error #{httpcode} when attempting to email listing id #{listing.id} of type #{type} to #{name} at #{email_address}. Errors: " <>
         (errors |> Enum.map(fn %{"code" => code, "message" => message} ->
           "Error code #{code}: #{message}"
         end)
         |> Enum.join(", "))
        )

      {:error, reason} ->
        Logger.error("ERROR: when attempting to email listing id #{listing.id} of type #{type} to #{name} at #{email_address}. Reason: #{inspect(reason)}")

      unknown ->
        Logger.error("ERROR: Attempting to email listing id #{listing.id} of type #{type} to #{name} at #{email_address} failed for unknown reasons: #{inspect(unknown)}")
    end
    delivery
  end

  defp interpolate_placeholder_values(nil, _, _), do: nil
  defp interpolate_placeholder_values(body, %{name: name, url: url}, default_name) do
    name =
      case name do
        "" -> default_name
        nil -> default_name
        _ -> name
      end

    body = Regex.replace(~r/@name_placeholder/, body, name)
    body = Regex.replace(~r/@listing_link_placeholder/, body, url)
    body
  end

  defp from_email do
    case Coherence.Config.email_from() do
      nil ->
        Logger.error(
          ~s|Need to configure :coherence, :email_from_name, "Name", and :email_from_email, "me@example.com"|
        )

        nil

      {name, email} = email_tuple ->
        if is_nil(name) or is_nil(email) do
          Logger.error(
            ~s|Need to configure :coherence, :email_from_name, "Name", and :email_from_email, "me@example.com"|
          )

          nil
        else
          email_tuple
        end
    end
  end
end
