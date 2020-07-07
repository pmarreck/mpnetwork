defmodule MpnetworkWeb.ListingController do
  use MpnetworkWeb, :controller

  require Logger

  alias Mpnetwork.{Realtor, Listing, ClientEmail, Repo, Mailer, Permissions}
  # alias Mpnetwork.Realtor.Office
  alias Mpnetwork.Listing.AttachmentMetadata

  alias Mpnetwork.Listing.LinkCodeGen

  plug(
    :put_layout,
    "public_listing.html" when action in [:client_full, :broker_full, :customer_full]
  )

  def search_help(conn, _params) do
    render(conn, "search_help.html")
  end

  # I wrote this function because String.to_integer puked sometimes
  # with certain spurious inputs and caused 500 errors.
  # Should probably be moved to a lib at some point.
  # This function is currently copied from attachment_controller.ex
  @filter_nondecimal ~r/[^0-9]+/
  defp unerring_string_to_int(bin) when is_binary(bin) do
    bin = Regex.replace(@filter_nondecimal, bin, "")

    case bin do
      "" -> nil
      val -> String.to_integer(val)
    end
  end

  defp unerring_string_to_int(n) when is_float(n), do: round(n)
  defp unerring_string_to_int(n) when is_integer(n), do: n
  defp unerring_string_to_int(_), do: nil

  def index(conn, %{"q" => query, "limit" => max} = _params) do
    max =
      case max do
        "" -> 50
        nil -> 50
        50 -> 50
        "50" -> 50
        100 -> 100
        "100" -> 100
        200 -> 200
        "200" -> 200
        500 -> 500
        "500" -> 500
        n -> unerring_string_to_int(n) || 1000
      end

    {total, listings, errors} = Realtor.query_listings(query, max, current_user(conn))
    primaries = Listing.primary_images_for_listings(listings)

    render(
      conn,
      "search_results.html",
      listings: listings,
      primaries: primaries,
      errors: errors,
      total: total,
      max: max
    )
  end

  # Round Robin landing view
  def index(conn, _params) do
    listings = Realtor.list_latest_listings_excluding_new(nil, 30)
    primaries = Listing.primary_images_for_listings(listings, AttachmentMetadata)
    # draft_listings = Realtor.list_latest_draft_listings(conn.assigns.current_user)
    # draft_primaries = Listing.primary_images_for_listings(draft_listings, AttachmentMetadata)
    upcoming_broker_oh_listings = Realtor.list_next_broker_oh_listings(nil, 30)

    upcoming_broker_oh_primaries =
      Listing.primary_images_for_listings(upcoming_broker_oh_listings, AttachmentMetadata)

    upcoming_cust_oh_listings = Realtor.list_next_cust_oh_listings(nil, 30)

    upcoming_cust_oh_primaries =
      Listing.primary_images_for_listings(upcoming_cust_oh_listings, AttachmentMetadata)

    render(
      conn,
      "index.html",
      listings: listings,
      primaries: primaries,
      upcoming_broker_oh_listings: upcoming_broker_oh_listings,
      upcoming_broker_oh_primaries: upcoming_broker_oh_primaries,
      upcoming_cust_oh_listings: upcoming_cust_oh_listings,
      upcoming_cust_oh_primaries: upcoming_cust_oh_primaries
    )
  end

  def inspection_sheet(conn, _params) do
    upcoming_broker_oh_listings = Realtor.list_next_broker_oh_listings(nil, 30)
    upcoming_cust_oh_listings = Realtor.list_next_cust_oh_listings(nil, 30)

    render(
      conn,
      "inspection_sheet.html",
      upcoming_broker_oh_listings: upcoming_broker_oh_listings,
      upcoming_cust_oh_listings: upcoming_cust_oh_listings
    )
  end

  # when receiving a "clone_id" param, clone the values from that id
  def new(conn, %{"clone_id" => clone_id} = _params) do
    if !Permissions.read_only?(current_user(conn)) do
      # |> Repo.preload([:user, :broker, :colisting_agent])
      listing = Realtor.get_listing!(clone_id)
      # broker = listing.broker
      # agent = listing.user
      # colisting_agent = listing.colisting_agent
      # Nil out or replace the values that are no longer relevant
      unless listing.listing_status_type in [:NEW, :FS, :EXT, :UC, :PC] do
        changeset =
          Realtor.change_listing(%{
            listing
            | user_id: current_user(conn).id,
              broker_id: conn.assigns.current_office && conn.assigns.current_office.id,
              live_at: nil,
              expires_on: nil,
              uc_on: nil,
              prop_closing_on: nil,
              closed_on: nil,
              closing_price_usd: nil,
              purchaser: nil,
              moved_from: nil,
              price_usd: nil,
              prior_price_usd: listing.price_usd,
              listing_status_type: nil,
              draft: true,
              for_sale: false,
              for_rent: false,
              owner_name: nil,
              status_showing_phone: nil,
              listing_agent_phone: nil,
              colisting_agent_phone: nil,
              addl_listing_agent_name: nil,
              addl_listing_agent_phone: nil,
              addl_listing_broker_name: nil,
              selling_agent_name: nil,
              selling_agent_phone: nil,
              selling_broker_name: nil
          })

        render(
          conn,
          "new.html",
          changeset: changeset,
          offices: offices(),
          users: users(conn.assigns.current_office, conn.assigns.current_user)
        )
      else
        send_resp(conn, 405, "You can only clone inactive listings")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def new(conn, _params) do
    if !Permissions.read_only?(current_user(conn)) do
      changeset =
        Realtor.change_listing(%Mpnetwork.Realtor.Listing{
          user_id: current_user(conn).id,
          broker_id: conn.assigns.current_office && conn.assigns.current_office.id
        })

      render(
        conn,
        "new.html",
        changeset: changeset,
        offices: offices(),
        users: users(conn.assigns.current_office, conn.assigns.current_user)
      )
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def create(conn, %{"listing" => listing_params}) do
    if !Permissions.read_only?(current_user(conn)) do
      # inject current_user.id and current_office.id (as broker_id)
      listing_params = Enum.into(%{"broker_id" => conn.assigns.current_office.id}, listing_params)
      listing_params = filter_empty_ext_urls(listing_params)

      case Realtor.create_listing(listing_params) do
        {:ok, listing} ->
          conn
          |> put_flash(:info, "Listing created successfully.")
          |> redirect(to: Routes.listing_path(conn, :show, listing))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(
            conn,
            "new.html",
            changeset: changeset,
            offices: offices(),
            users: users(conn.assigns.current_office, conn.assigns.current_user)
          )
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def show(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id) |> Repo.preload([:user, :broker, :colisting_agent])
    broker = listing.broker
    agent = listing.user
    colisting_agent = listing.colisting_agent
    attachments = Listing.list_attachments(id, AttachmentMetadata)

    render(
      conn,
      "show.html",
      listing: listing,
      broker: broker,
      agent: agent,
      colisting_agent: colisting_agent,
      attachments: attachments
    )
  end

  def edit(conn, %{"id" => id}) do
    if !Permissions.read_only?(current_user(conn)) do
      listing = Realtor.get_listing!(id)

      if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
        attachments = Listing.list_attachments(listing.id, AttachmentMetadata)
        changeset = Realtor.change_listing(listing)

        render(
          conn,
          "edit.html",
          listing: listing,
          attachments: attachments,
          changeset: changeset,
          broker: listing.broker,
          offices: offices(),
          users: users(conn.assigns.current_office, conn.assigns.current_user)
        )
      else
        send_resp(conn, 405, "Not allowed")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  # def edit_mls(conn, %{"id" => id}) do
  #   listing = Realtor.get_listing!(id)
  #   ensure_owner_or_admin(conn, listing, fn ->
  #     attachments = Listing.list_attachments(listing.id)
  #     changeset = Realtor.change_listing(listing)
  #     render(conn, "edit_mls.html",
  #       listing: listing,
  #       attachments: attachments,
  #       changeset: changeset,
  #       offices: offices(),
  #       users: users(conn.assigns.current_office, conn.assigns.current_user)
  #     )
  #   end)
  # end

  def update(conn, %{"id" => id, "listing" => listing_params}) do
    # IO.inspect listing_params, limit: :infinity
    if !Permissions.read_only?(current_user(conn)) do
      listing = Realtor.get_listing!(id)
      listing_params = filter_empty_ext_urls(listing_params)

      if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
        case Realtor.update_listing(listing, listing_params) do
          {:ok, listing} ->
            conn
            |> put_flash(:info, "Listing updated successfully.")
            |> redirect(to: Routes.listing_path(conn, :show, listing))

          {:error, %Ecto.Changeset{} = changeset} ->
            attachments = Listing.list_attachments(id, AttachmentMetadata)

            render(
              conn,
              "edit.html",
              listing: listing,
              attachments: attachments,
              changeset: changeset,
              offices: offices(),
              users: users(conn.assigns.current_office, conn.assigns.current_user)
            )
        end
      else
        send_resp(conn, 405, "Not allowed")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def delete(conn, %{"id" => id}) do
    if !Permissions.read_only?(current_user(conn)) do
      listing = Realtor.get_listing!(id)

      if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
        {:ok, _listing} = Realtor.delete_listing(listing)

        conn
        |> put_flash(:info, "Listing deleted successfully.")
        |> redirect(to: Routes.listing_path(conn, :index))
      else
        send_resp(conn, 405, "Not allowed")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def broker_full(conn, %{"id" => signature}) do
    _do_public_listing(conn, signature, :broker)
  end

  def client_full(conn, %{"id" => signature}) do
    _do_public_listing(conn, signature, :client)
  end

  def customer_full(conn, %{"id" => signature}) do
    _do_public_listing(conn, signature, :customer)
  end

  defp _do_public_listing(conn, signature, type_of_listing) do
    {decrypted_id, decrypted_expiration_date} = LinkCodeGen.from_listing_code(signature, type_of_listing)

    listing =
      Realtor.get_listing!(decrypted_id) |> Repo.preload([:user, :broker, :colisting_agent])

    broker = listing.broker
    agent = listing.user
    co_agent = listing.colisting_agent
    id = listing.id
    %{^id => showcase_image} = Listing.primary_images_for_listings([listing], AttachmentMetadata)
    attachments = Listing.list_attachments(id, AttachmentMetadata)

    case DateTime.compare(decrypted_expiration_date, Timex.now()) do
      :gt ->
        render(
          conn,
          "#{type_of_listing}_full.html",
          listing: listing,
          broker: broker,
          agent: agent,
          co_agent: co_agent,
          showcase_image: showcase_image,
          attachments: attachments
        )

      _ ->
        # 410 is "Gone"
        send_resp(conn, 410, "Link has expired")
    end
  end

  def email_listing(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    # if current_user(conn).id == listing.user_id || current_user(conn).role_id < 3 do
    render(conn, "email_listing.html", listing: listing)
    # else
    #   send_resp(conn, 405, "Not allowed to email a listing that is not yours")
    # end
  end

  defp parse_names_emails(names_emails) when is_binary(names_emails) do
    import Mpnetwork.Utils.Regexen
    results = Regex.scan(email_parsing_regex(), names_emails)

    results
    |> Enum.map(fn result ->
      result =
        case result do
          [_full, "", "", "", "", email] -> {nil, email}
          [_full, quoted_name, "", "", unquoted_email] -> {quoted_name, unquoted_email}
          [_full, "", name, "", email] -> {name, email}
          [_full, "", "", email] -> {nil, email}
          [_full, "", bare_name, email] -> {bare_name, email}
          [_full, quoted_name, "", email] -> {quoted_name, email}
          [_full, _, _, email] -> {nil, email}
          [_full, _, _, _, email] -> {nil, email}
          [_full, _, _, _, _, email] -> {nil, email}
        end

      {name, email} = result
      %{name: name, email: email}
    end)
  end

  defp unparse_names_emails(names_emails_list) when is_list(names_emails_list) do
    names_emails_list
    |> Enum.map(fn %{name: name, email: email} ->
      case name do
        nil -> email
        _ -> "\"#{name}\" <#{email}>"
      end
    end)
    |> Enum.join(", ")
  end

  def send_email(conn, %{"id" => id, "email" => %{"names_emails" => ""}}) do
    conn
    |> put_flash(
      :error,
      "ERROR: At least one email address is required"
    )
    |> redirect(to: Routes.email_listing_path(conn, :email_listing, id))
  end

  def send_email(
        conn,
        %{
          "id" => id,
          "email" => %{
            "type" => type,
            "names_emails" => names_emails,
            "subject" => subject,
            "body" => body,
            "cc_self" => cc_self
          }
        } = _params
      )
      when type in ~w[broker client customer] do
    # checkboxes come in this way...
    cc_self = cc_self == "true"
    listing = Realtor.get_listing!(id) |> Repo.preload(:user)
    current_user = conn.assigns.current_user
    id = listing.id

    url =
      case type do
        "broker" ->
          Routes.public_broker_full_url(conn, :broker_full, LinkCodeGen.public_broker_full_code(listing))

        "client" ->
          Routes.public_client_full_url(conn, :client_full, LinkCodeGen.public_client_full_code(listing))

        "customer" ->
          Routes.public_customer_full_url(conn, :customer_full, LinkCodeGen.public_customer_full_code(listing))

        _ ->
          raise "unknown public listing type: #{type}"
      end

    parsed_names_emails = parse_names_emails(names_emails)
    # if there were email addresses detected...
    if parsed_names_emails != [] do
      sent_emails =
        parsed_names_emails
        |> Enum.map(fn %{name: name, email: email} ->
          ClientEmail.send_client(
            email,
            if(name, do: name, else: ""),
            subject,
            body,
            current_user,
            listing,
            url,
            cc_self
          )
        end)

      success_fail_emails =
        sent_emails
        |> Enum.map(fn sent_email ->
          {name, email} = List.first(sent_email.to)

          {success, results} =
            case Mailer.deliver(sent_email) do
              {:ok, results} ->
                {true, results}

              {:error, :timeout} ->
                {false, :timeout}

              {:error, {httpcode, %{"errors" => errors}}}
              when is_integer(httpcode) and is_list(errors) ->
                {false,
                 errors
                 |> Enum.map(fn %{"code" => code, "message" => message} ->
                   "Error code #{code}: #{message}"
                 end)
                 |> Enum.join(", ")}

              {:error, reason} ->
                {false, inspect(reason)}

              unknown ->
                {false, unknown}
            end

          case {success, results, name, email} do
            {true, results, ^name, ^email} ->
              Logger.info(
                "Sent listing id #{id} of type #{type} to #{name} at #{email}#{
                  if cc_self, do: " (cc'ing self)", else: ""
                }, result: #{inspect(results)}"
              )

            {false, :timeout, ^name, ^email} ->
              Logger.info(
                "TIMED OUT emailing listing id #{id} of type #{type} to #{name} at #{email}"
              )

            {false, reason, ^name, ^email} ->
              Logger.info(
                "Error emailing listing id #{id} of type #{type} to #{name} at #{email}, reason given: #{
                  inspect(reason)
                }"
              )
          end

          {success, results, name, email}
        end)

      overall_success = success_fail_emails |> Enum.all?(fn {s, _r, _n, _e} -> s end)
      fails = success_fail_emails |> Enum.filter(fn {success, _reason, _n, _e} -> !success end)

      fail_reasons =
        fails |> Enum.map(fn {_failure, reason, _n, _e} -> "#{reason}" end) |> Enum.join("; ")

      case overall_success do
        true ->
          conn
          |> put_flash(
            :info,
            "Listing emailed to these recipients successfully: #{
              unparse_names_emails(parsed_names_emails)
            }" <> if(cc_self, do: ". You were bcc'd on every email.", else: "")
          )
          |> redirect(to: Routes.listing_path(conn, :show, id))

        false ->
          conn
          |> put_flash(
            :error,
            "ERROR: Trying to email this listing to some of the email addresses failed for some reason. Please try again. Actual error(s): #{
              fail_reasons
            }"
          )
          |> redirect(to: Routes.email_listing_path(conn, :email_listing, id))
      end
    else
      conn
      |> put_flash(:error, "ERROR: No valid email addresses were detected")
      |> redirect(to: Routes.email_listing_path(conn, :email_listing, id))
    end
  end

  defp offices do
    Realtor.list_offices()
  end

  # defp users do
  #   Realtor.list_users
  # end

  defp users(office, current_user) do
    if Permissions.site_admin?(current_user) do
      Realtor.list_users()
    else
      Realtor.list_users(office)
    end
  end

  # defp ensure_owner_or_admin(conn, resource, lambda) do
  #   u = current_user(conn)
  #   oid = resource.user_id
  #   admin = u.role_id < 3
  #   if u.id == oid || admin do
  #     lambda.()
  #   else
  #     send_resp(conn, 405, "Not allowed")
  #   end
  # end

  defp filter_empty_ext_urls(listing_params) do
    if listing_params["ext_urls"] do
      %{"ext_urls" => ext_urls} = listing_params

      if ext_urls do
        ext_urls = Enum.filter(ext_urls, &(&1 != ""))
        Enum.into(%{"ext_urls" => ext_urls}, listing_params)
      else
        listing_params
      end
    else
      listing_params
    end
  end
end
