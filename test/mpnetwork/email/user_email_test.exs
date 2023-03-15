defmodule Mpnetwork.UserEmailTest do
  use Mpnetwork.DataCase, async: true
  # use ExUnit.Case, async: true

  # alias Mpnetwork.{Listing, Upload, Realtor}

  alias Mpnetwork.UserEmail

  import Mpnetwork.Test.Support.Utilities
  import Swoosh.TestAssertions

  describe "user emails" do

    test "send_user_regarding_listing doesn't break" do
      user = user_fixture()
      listing = fixture(:listing, user)
      subject = "this is a test"
      htmlbody = "<h1>HI!</h1>"
      textbody = "HI!"
      type = "notify_user_of_impending_omd_expiry"
      sent_email = UserEmail.send_user_regarding_listing(user, listing, subject, htmlbody, textbody, type)
{status, {email, email_rendered, results}} = sent_email
IO.inspect {status, {email, email_rendered, results}}
      assert_email_sent sent_email
    end
  end
end
