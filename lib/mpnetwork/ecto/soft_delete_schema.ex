defmodule Mpnetwork.Ecto.SoftDelete.Schema do
  @moduledoc """
  Module to be `use`-d in place of `Ecto.Schema` for all schemas with soft-delete functionality
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      @timestamps_opts [type: :utc_datetime_usec]
      @schema_prefix "without_softdeleted"
    end
  end
end
