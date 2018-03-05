defmodule MpnetworkWeb.GlobalHelpers do
  use Phoenix.HTML

  @roles {"Root", "Site Admin", "Office Admin", "Realtor", "Read-only"}
  @roles_as_list Tuple.to_list(@roles)
  @roles_with_idx Enum.with_index(@roles_as_list)

  def roles, do: @roles
  def roles_as_list, do: @roles_as_list
  def roles_with_index, do: @roles_with_idx

  def role_id_to_name(role_id) do
    elem(roles(), role_id)
  end

  def gravatar_url(email) do
    hash_email = :crypto.hash(:md5, email) |> Base.encode16() |> String.downcase()
    "https://www.gravatar.com/avatar/#{hash_email}"
  end

  def replace_crlf_with_html_br(str) do
    Regex.replace(~r/(?:\r\n|\r|\n)/, str, "<br />\n")
  end

  ### DATETIME-RELATED ###
  def month_to_short_name(nil), do: ""

  def month_to_short_name(month_num) do
    elem(
      {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"},
      month_num - 1
    )
  end

  def short_month_and_year(nil), do: ""

  def short_month_and_year(ecto_datetime) do
    month_to_short_name(ecto_datetime.month) <> " " <> Integer.to_string(ecto_datetime.year)
  end

  def last_logged_in_relative_humanized(user) do
    # TODO: Fix when native elixir datetime support is enhanced.
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

  # this is hairy but gets the job done
  # ...aaaaand commented out since they changed the requirements sigh
  # Left in since it was nice and took a little work.
  # def relative_humanized_time_with_hours_and_minutes(%NaiveDateTime{} = naive_datetime) do
  #   DateTime.utc_now()
  #   |> Timex.diff(naive_datetime, :duration)
  #   |> Timex.Duration.to_minutes()
  #   |> Float.floor()
  #   |> Timex.Duration.from_minutes()
  #   |> Timex.format_duration(:humanized)
  #   # Regex.replace(~r/(?:ays?|ours?|inutes?)/, fmt, "")
  # end

  defp convert_ecto_datetime_to_utc_datetime(%Ecto.DateTime{} = edt) do
    edt
    |> Ecto.DateTime.to_erl()
    |> NaiveDateTime.from_erl!()
    |> DateTime.from_naive!("Etc/UTC")
  end

  def current_datetime_standard_humanized(tz \\ "EDT") do
    Timex.now(tz) |> Timex.format!("%a, %b %e, %Y %l:%M:%S %p", :strftime)
  end

  def datetime_to_standard_humanized(_, format \\ "%a, %b %e, %Y %l:%M %p", tz \\ "EDT")
  def datetime_to_standard_humanized(nil, _, _), do: ""
  def datetime_to_standard_humanized("", _, _), do: ""

  def datetime_to_standard_humanized(%Ecto.DateTime{} = datetime, format, tz) do
    datetime
    |> Ecto.DateTime.to_erl()
    |> NaiveDateTime.from_erl!()
    |> datetime_to_standard_humanized(format, tz)
  end

  def datetime_to_standard_humanized(%NaiveDateTime{} = naive_datetime, format, tz) do
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> Timex.Timezone.convert(tz)
    |> Timex.format!(format, :strftime)
  end

  def datetime_to_standard_humanized(%Date{} = date, format, _tz) do
    date
    |> Timex.format!(format, :strftime)
  end

  def utc_date_to_local_date(date, format \\ "%-m/%-d/%Y", tz \\ "EDT") do
    datetime_to_standard_humanized(date, format, tz)
  end

  # convert falsey values to "N", anything else to "Y"
  def yn(bool), do: if(bool, do: "Y", else: "N")

  # convert an integer number of dollars to dollar format
  def dollars(val) when is_number(val), do: Number.Currency.number_to_currency(val, precision: 0)
  def dollars(_), do: ""

  # convert basis points to percent and fraction
  @frac_portion_to_frac %{0 => "", 25 => "¼", 50 => "½", 75 => "¾"}
  def basis_points_to_fractional_percent(0), do: ""

  def basis_points_to_fractional_percent(points) when is_integer(points) do
    frac_portion = rem(points, 100)
    whole_portion = div(points, 100)
    "#{if whole_portion == 0, do: "", else: whole_portion}#{@frac_portion_to_frac[frac_portion]}%"
  end

  @content_type_to_icon_class_map %{
    # PDF
    "application/pdf" => "fa fa-fw fa-file-pdf-o",
    # MS Office formats
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =>
      "fa fa-fw fa-file-word-o",
    "application/msword" => "fa fa-fw fa-file-word-o",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =>
      "fa fa-fw fa-file-excel-o",
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
    "image/gif" => "fa fa-fw fa-file-image-o",
    "image/png" => "fa fa-fw fa-file-image-o",
    "image/bmp" => "fa fa-fw fa-file-image-o",
    "image/psd" => "fa fa-fw fa-file-image-o",
    "image/tiff" => "fa fa-fw fa-file-image-o",
    "image/webp" => "fa fa-fw fa-file-image-o",
    "image/flif" => "fa fa-fw fa-file-image-o"
  }

  def html_icon_class_by_content_type(content_type) do
    # use as a class on an i element
    Map.get(@content_type_to_icon_class_map, content_type, "fa fa-fw fa-file-o")
  end

  def to_atom(name) when is_binary(name), do: String.to_existing_atom(name)
  def to_atom(name) when is_atom(name), do: name

  # datalist element
  def datalist_input(f, name, %{list_name: list_name, data: list} = attrs) do
    struct_name = if f, do: "#{f.name}[#{name}]", else: "#{name}"

    val =
      if f do
        source = Map.get(f, :source)

        if source do
          changes = Map.get(source, :changes)

          if changes do
            changed_val = Map.get(changes, to_atom(name))

            if changed_val do
              changed_val
            else
              Map.get(f.data, name)
            end
          else
            Map.get(f.data, name)
          end
        else
          Map.get(f.data, name)
        end
      else
        nil
      end

    attrs =
      attrs
      |> Map.put(:type, "text")
      |> Map.put(:list, list_name)
      |> Map.put(:name, struct_name)
      |> Map.delete(:data)
      |> Map.delete(:list_name)

    attrs = if val, do: Map.put(attrs, :value, val), else: attrs
    attrs_html = Enum.map_join(attrs, " ", fn {x, y} -> ~s(#{x}="#{y}") end)
    opts_html = Enum.map_join(list, "\n", fn x -> ~s(<option value="#{x}">) end)
    raw(~s(<input #{attrs_html} />\n<datalist id="#{list_name}">\n#{opts_html}\n</datalist>))
  end

  def datalist_input(name, %{} = attrs) do
    datalist_input(nil, name, attrs)
  end

  @blank_select_opt {" ", nil}
  def prepend_blank_select_opt([]) do
    [@blank_select_opt]
  end

  def prepend_blank_select_opt([_ | _] = one_or_more) do
    [@blank_select_opt | one_or_more]
  end
end
