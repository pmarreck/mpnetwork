defmodule Mpnetwork.Ecto.Schema do
  @moduledoc """
  Module to be `use`-d in place of `Ecto.Schema` for all schemas.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      @timestamps_opts [type: :utc_datetime_usec]
      @schema_prefix "public"
    end
  end
end
