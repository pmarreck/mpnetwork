defmodule Mpnetwork.Workers.NewListingEmailer do
  @attempts 10

  use Oban.Worker,
    queue: :mailers,
    priority: 1,
    max_attempts: @attempts + 1,
    tags: ["new_listing_notif"],
    unique: [period: 60]

  require Logger
  alias Mpnetwork.{Repo, UserEmail, User}
  alias Mpnetwork.Realtor.Listing


  @impl Oban.Worker
  def perform(%Oban.Job{attempt: attempt} = job) when attempt == (@attempts + 1) do
    msg = "ERROR: Oban job failed #{@attempts} times: #{inspect(job)}"
    Logger.error(msg)
    {:error, msg}
  end

  def perform(%Oban.Job{args: %{"listing_id" => listing_id, "user_id" => user_id}} = _oban_job) do
    user = Repo.get!(User, user_id)
    name = user.name
    listing = Repo.get!(Listing, listing_id) |> Repo.preload([:attachments, :broker, :user, :colisting_agent])
    subject_tag = "[MPWREB]"
    announce = case listing.listing_status_type do
      :NEW -> "NEW! "
      :FS  -> "FOR SALE! "
      :CS  -> "COMING SOON! "
      :EXT -> "EXTENDED! "
      :PC  -> "PRICE CHANGE! "
      _    -> ""
    end
    subject_address = listing.address
    subject_address = if listing.city do
      subject_address <> ", #{listing.city}"
    else
      subject_address
    end
    subject = "#{subject_tag} #{announce}#{subject_address}"
    body_preamble = "Hello #{name}! Please click here to check it out: "
    sent_email = UserEmail.send_user_regarding_listing(
      user,
      listing,
      subject,
      "<html><body>" <> body_preamble <> "<a href='@listing_link_placeholder'>@listing_link_placeholder</a>" <> "</body></html>",
      body_preamble <> "@listing_link_placeholder",
      "new_listing_notif"
    )
    sent_email
  end
end
