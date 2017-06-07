defmodule Mpnetwork.Web.GlobalHelpers do

  def month_to_short_name(month_num) do
    elem({"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}, month_num - 1)
  end

  def short_month_and_year(ecto_datetime) do
    month_to_short_name(ecto_datetime.month) <> " " <> Integer.to_string(ecto_datetime.year)
  end

  def gravatar_url(email) do
    hash_email = :crypto.hash(:md5, email) |> Base.encode16 |> String.downcase
    "https://www.gravatar.com/avatar/#{hash_email}"
  end

end