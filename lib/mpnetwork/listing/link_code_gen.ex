defmodule Mpnetwork.Listing.LinkCodeGen do
  alias Mpnetwork.Crypto

  @doc """
  Computes the link code for an emailed broker listing.

  ## Examples

      iex> public_broker_full_code(listing)
      "f3o427dr2kpe2bdxzoswbaivcpqt4g7xuqd3xey2dnv7lm4yylhq"

  """
  def public_broker_full_code(
        listing,
        expiration_days_since_unix_epoch \\ two_weeks_from_now_in_unix_epoch_days()
      ) do
    do_listing_code(listing, :broker, expiration_days_since_unix_epoch)
  end

  @doc """
  Computes the link code for an emailed client listing.

  ## Examples

      iex> public_client_full_code(listing)
      "f3o427dr2kpe2bdxzoswbaivcpqt4g7xuqd3xey2dnv7lm4yylhq"

  """
  def public_client_full_code(
        listing,
        expiration_days_since_unix_epoch \\ two_weeks_from_now_in_unix_epoch_days()
      ) do
    do_listing_code(listing, :client, expiration_days_since_unix_epoch)
  end

  @doc """
  Computes the link code for an emailed customer listing.

  ## Examples

      iex> public_customer_full_code(listing)
      "f3o427dr2kpe2bdxzoswbaivcpqt4g7xuqd3xey2dnv7lm4yylhq"

  """
  def public_customer_full_code(
        listing,
        expiration_days_since_unix_epoch \\ two_weeks_from_now_in_unix_epoch_days()
      ) do
    do_listing_code(listing, :customer, expiration_days_since_unix_epoch)
  end

  defp do_listing_code(listing, recipient_type, expiration_days_since_unix_epoch) do
    {listing.id, expiration_days_since_unix_epoch, recipient_type}
    |> Crypto.encrypt()
  end

  def from_listing_code(ciphertext, recip) do
    {listing_id, exp_day, ^recip} = Crypto.decrypt(ciphertext)
    {listing_id, timex_datetime_from_unix_epoch_days(exp_day)}
  end

  def now_in_unix_epoch_days do
    in_unix_epoch_days()
  end

  def in_unix_epoch_days(time \\ Timex.today()) do
    (Timex.to_unix(time) / (60 * 60 * 24)) |> trunc
  end

  defp two_weeks_from_now_in_unix_epoch_days do
    now_in_unix_epoch_days() + 14
  end

  defp timex_datetime_from_unix_epoch_days(days) do
    Timex.from_unix(days * 24 * 60 * 60)
  end
end
