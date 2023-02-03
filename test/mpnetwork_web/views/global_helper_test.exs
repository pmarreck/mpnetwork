defmodule Mpnetwork.GlobalHelperTest do
  use ExUnit.Case, async: true
  alias MpnetworkWeb.GlobalHelpers, as: H

  test "renders datalist properly" do
    f = %{name: "listing", data: %{input_name: 10}}

    assert H.datalist_input(f, :input_name, %{
             id: "test",
             list_name: "list_name",
             data: ~w[a b c d e]
           }) ==
             {:safe,
              ~s(<input id="test" list="list_name" name="listing[input_name]" type="text" value="10" />\n<datalist id="list_name">\n<option value="a">\n<option value="b">\n<option value="c">\n<option value="d">\n<option value="e">\n</datalist>)}

    assert H.datalist_input("input_name", %{id: "test", list_name: "list_name", data: ~w[a b]}) ==
             {:safe,
              ~s(<input id="test" list="list_name" name="input_name" type="text" />\n<datalist id="list_name">\n<option value="a">\n<option value="b">\n</datalist>)}
  end

  test "renders datetime_to_standard_humanized properly" do
    # specifying a format using a naive datetime
    assert H.datetime_to_standard_humanized(~N[2019-01-01 00:00:00Z], "%a %b %e %Y") == "Mon Dec 31 2018"
    # using default format with a naive datetime
    assert H.datetime_to_standard_humanized(~N[2019-01-01 00:00:00Z]) == "Mon, Dec 31, 2018  7:00 PM"
    # using default format with a date
    assert H.datetime_to_standard_humanized(~D[1972-04-05]) == "Wed, Apr  5, 1972 12:00 AM"
    # using default format with a UTC datetime
    assert H.datetime_to_standard_humanized(~U[2010-10-10 10:10:10Z]) == "Sun, Oct 10, 2010  6:10 AM"
  end

  test "y/n Yes/No renderer from boolean" do
    assert H.yn(true) == "Y"
    assert H.yn(false) == "N"
    assert H.yesno(true) == "Yes"
    assert H.yesno(nil) == "No"
  end
  
  test "dollars" do
    assert H.dollars(100.40) == "$100"
  end

  test "basis_points_to_fractional_percent" do
    assert H.basis_points_to_fractional_percent(100) == "1%"
    assert H.basis_points_to_fractional_percent(5000) == "50%"
  end

  test "html_icon_class_by_content_type" do
    assert H.html_icon_class_by_content_type("image/jpeg") == "fa fa-fw fa-file-image-o"
    # unknown content type
    assert H.html_icon_class_by_content_type("unknown/unknown") == "fa fa-fw fa-file-o"
  end

end
