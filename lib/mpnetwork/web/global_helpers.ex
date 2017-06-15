defmodule Mpnetwork.Web.GlobalHelpers do

  @roles {"Root","Site Admin","Office Admin","Realtor","User"}

  def role_id_to_name(role_id) do
    elem(@roles, role_id)
  end

  def gravatar_url(email) do
    hash_email = :crypto.hash(:md5, email) |> Base.encode16 |> String.downcase
    "https://www.gravatar.com/avatar/#{hash_email}"
  end

  ### DATETIME-RELATED ###
  def month_to_short_name(month_num) do
    elem({"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}, month_num - 1)
  end

  def short_month_and_year(ecto_datetime) do
    month_to_short_name(ecto_datetime.month) <> " " <> Integer.to_string(ecto_datetime.year)
  end

  def last_logged_in_relative_humanized(user) do
    #TODO: Fix when native elixir datetime support is enhanced.
    # This solution is complicated due to no timezone info in NaiveDateTime
    # and the assumption that it is UTC.
    # Depends on the Timex library to work.
    "Last sign-in: " <> relative_humanized_time(user.last_sign_in_at)
  end

  def relative_humanized_time(nil) do
    "NEVER! Welcome!"
  end

  def relative_humanized_time(%Ecto.DateTime{} = ecto_datetime) do
    utc_datetime = ecto_datetime |> convert_ecto_datetime_to_utc_datetime
    relative_humanized_time(utc_datetime)
  end

  def relative_humanized_time(%DateTime{} = datetime) do
    {:ok, fmt} = Timex.format(datetime, "{relative}", :relative)
    fmt
  end

  def relative_humanized_time(%NaiveDateTime{} = naive_datetime) do
    {:ok, fmt} = Timex.format(naive_datetime, "{relative}", :relative)
    fmt
  end

  defp convert_ecto_datetime_to_utc_datetime(%Ecto.DateTime{} = edt) do
    edt
      |> Ecto.DateTime.to_erl
      |> NaiveDateTime.from_erl!
      |> DateTime.from_naive!("Etc/UTC")
  end

  def current_datetime_standard_humanized(tz \\ "EDT") do
    # I have no idea why I had to shift this because it was off by 1 hour.
    # DST or something?
    Timex.now(tz) |> Timex.format!("%a, %b %e, %Y %l:%M:%S %p", :strftime)
  end

end