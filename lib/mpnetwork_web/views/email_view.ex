defmodule Mpnetwork.EmailView do
  use MpnetworkWeb, :view
  def nextphoto(nil), do: {nil, nil}
  def nextphoto([]), do: {nil, nil}
  def nextphoto([head | rest]), do: {head, rest}
end
