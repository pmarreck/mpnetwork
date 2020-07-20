Code.ensure_loaded(Phoenix.Swoosh)

defmodule Mpnetwork.UserEmail do
  @moduledoc false
  use Phoenix.Swoosh, view: Mpnetwork.EmailView, layout: {MpnetworkWeb.LayoutView, :email}
  import Swoosh.Email
  alias Swoosh.Email
  alias Mpnetwork.Mailer
  alias MpnetworkWeb.Endpoint
  alias MpnetworkWeb.Router.Helpers, as: Routes
  require Logger


  def send_user_regarding_listing(user, listing, subject, body, type \\ "notify_user_of_impending_omd_expiry") do
    name = user.name
    email_address = user.email
    url = Routes.listing_url(Endpoint, :show, listing)
    body = interpolate_placeholder_values(body, %{name: name, url: url}, "User")

    fr = from_email()

    email =
      %Email{}
      |> from(fr)
      |> to({name, email_address})
      |> reply_to(fr)
      |> subject(subject)
      |> html_body(body)
      |> render_body("listing_email.html", %{html_body: body})

    case Mailer.deliver(email) do
      {:ok, results} ->
        Logger.info(
          "SUCCESS: Sent listing id #{listing.id} of type #{type} to #{name} at #{email_address}, result: #{inspect(results)}"
        )

      {:error, :timeout} ->
        Logger.info(
          "ERROR: TIMED OUT emailing listing id #{listing.id} of type #{type} to #{name} at #{email_address}"
        )

      {:error, {httpcode, %{"errors" => errors}}}
      when is_integer(httpcode) and is_list(errors) ->
        Logger.info("ERROR: HTTP error #{httpcode} when attempting to email listing id #{listing.id} of type #{type} to #{name} at #{email_address}. Errors: " <>
         (errors |> Enum.map(fn %{"code" => code, "message" => message} ->
           "Error code #{code}: #{message}"
         end)
         |> Enum.join(", "))
        )

      {:error, reason} ->
        Logger.info("ERROR: when attempting to email listing id #{listing.id} of type #{type} to #{name} at #{email_address}. Reason: #{inspect(reason)}")

      unknown ->
        Logger.info("ERROR: Attempting to email listing id #{listing.id} of type #{type} to #{name} at #{email_address} failed for unknown reasons: #{inspect(unknown)}")
    end
  end

  defp interpolate_placeholder_values(body, %{name: name, url: url}, alt_name) do
    name =
      case name do
        "" -> alt_name
        nil -> alt_name
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