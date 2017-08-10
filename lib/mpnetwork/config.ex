defmodule Mpnetwork.Config do
  def get(key) do
    Application.get_env(:mpnetwork, key)
  end
end
