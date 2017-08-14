defmodule Mpnetwork.GlobalHelperTest do
  use MpnetworkWeb.ConnCase, async: true
  alias MpnetworkWeb.GlobalHelpers, as: H

  test "renders datalist properly" do
    f = %{name: "listing"}
    assert H.datalist_input(f, "input_name", %{id: "test", list_name: "list_name", data: ~w[a b c d e]}) ==
      {:safe, ~s(<input id="test" list="list_name" name="listing[input_name]" type="text" />\n<datalist id="list_name">\n<option value="a">\n<option value="b">\n<option value="c">\n<option value="d">\n<option value="e">\n</datalist>)}
    assert H.datalist_input("input_name", %{id: "test", list_name: "list_name", data: ~w[a b]}) ==
      {:safe, ~s(<input id="test" list="list_name" name="input_name" type="text" />\n<datalist id="list_name">\n<option value="a">\n<option value="b">\n</datalist>)}
  end
end
