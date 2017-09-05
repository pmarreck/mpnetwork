defmodule MpnetworkWeb.GlobalHelpers do

  use Phoenix.HTML

  @roles {"Root", "Site Admin", "Office Admin", "Realtor", "User"}

  def role_id_to_name(role_id) do
    elem(@roles, role_id)
  end

  def gravatar_url(email) do
    hash_email = :crypto.hash(:md5, email) |> Base.encode16 |> String.downcase
    "https://www.gravatar.com/avatar/#{hash_email}"
  end

  ### DATETIME-RELATED ###
  def month_to_short_name(nil), do: ""
  def month_to_short_name(month_num) do
    elem({"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}, month_num - 1)
  end

  def short_month_and_year(nil), do: ""
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
    Timex.now(tz) |> Timex.format!("%a, %b %e, %Y %l:%M:%S %p", :strftime)
  end

  # convert falsey values to "N", anything else to "Y"
  def yn(bool), do: if bool, do: "Y", else: "N"

  # convert an integer number of dollars to dollar format
  def dollars(val) when is_number(val), do: Number.Currency.number_to_currency(val, precision: 0)
  def dollars(_), do: ""

  @content_type_to_icon_class_map %{
    # PDF
    "application/pdf" => "fa fa-fw fa-file-pdf-o",
    # MS Office formats
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "fa fa-fw fa-file-word-o",
    "application/msword" => "fa fa-fw fa-file-word-o",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => "fa fa-fw fa-file-excel-o",
    "application/vnd.ms-excel" => "fa fa-fw fa-file-excel-o",
    # Compression formats
    "application/zip" => "fa fa-fw fa-file-zip-o",
    "application/x-7z-compressed" => "fa fa-fw fa-file-zip-o",
    "application/x-gzip" => "fa fa-fw fa-file-zip-o",
    "application/x-bzip2" => "fa fa-fw fa-file-zip-o",
    "application/x-gtar" => "fa fa-fw fa-file-zip-o",
    "application/x-rar-compressed" => "fa fa-fw fa-file-zip-o",
    # Plain text doc
    "text/plain" => "fa fa-fw fa-file-text-o",
    # Video formats
    "video/mp4" => "fa fa-fw fa-file-video-o",
    "video/x-ms-wmv" => "fa fa-fw fa-file-video-o",
    "video/x-msvideo" => "fa fa-fw fa-file-video-o",
    "video/quicktime" => "fa fa-fw fa-file-video-o",
    "video/3gpp" => "fa fa-fw fa-file-video-o",
    "video/x-flv" => "fa fa-fw fa-file-video-o",
    "video/mpeg" => "fa fa-fw fa-file-video-o",
    # Image formats
    "image/svg+xml" => "fa fa-fw fa-file-image-o",
    "image/jpeg" => "fa fa-fw fa-file-image-o",
    "image/gif"  => "fa fa-fw fa-file-image-o",
    "image/png"  => "fa fa-fw fa-file-image-o",
    "image/bmp"  => "fa fa-fw fa-file-image-o",
    "image/psd"  => "fa fa-fw fa-file-image-o",
    "image/tiff" => "fa fa-fw fa-file-image-o",
    "image/webp" => "fa fa-fw fa-file-image-o",
    "image/flif" => "fa fa-fw fa-file-image-o",
  }

  def html_icon_class_by_content_type(content_type) do
    # use as a class on an i element
    Map.get(@content_type_to_icon_class_map, content_type, "fa fa-fw fa-file-o")
  end

  # datalist element
  def datalist_input(f, name, %{list_name: list_name, data: list} = attrs) do
    struct_name = if f, do: "#{f.name}[#{name}]", else: "#{name}"
    attrs = attrs
    |> Map.put(:type, "text")
    |> Map.put(:list, list_name)
    |> Map.put(:name, struct_name)
    |> Map.delete(:data)
    |> Map.delete(:list_name)
    attrs_html = Enum.map_join(attrs, " ", fn({x,y}) -> ~s(#{x}="#{y}") end)
    opts_html = Enum.map_join(list, "\n", fn(x) -> ~s(<option value="#{x}">) end)
    raw ~s(<input #{attrs_html} />\n<datalist id="#{list_name}">\n#{opts_html}\n</datalist>)
  end
  def datalist_input(name, %{} = attrs) do
    datalist_input(nil, name, attrs)
  end

  def is_admin(conn) do
    conn.assigns.current_user.role_id < 3
  end

end
