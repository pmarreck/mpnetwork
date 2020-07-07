defmodule Mpnetwork.Utils.NoopHash do
  # This conforms to the API for Comeonin.Bcrypt to enable Coherence to work with it in the test environment.

  # It literally just passes it through unhashed.

  # MUCH faster than Bcrypt >..<

  # Note that later versions of the comeonin bcrypt code use a different API

  def hashpwsalt(str), do: str

  def checkpw(str, str), do: true

  # ...that's it
end
