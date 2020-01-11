defmodule Mpnetwork.Coherence.Rememberable do
  @moduledoc false
  use Mpnetwork.Ecto.Schema

  import Ecto.Query

  alias Coherence.Config

  schema "rememberables" do
    field(:series_hash, :string)
    field(:token_hash, :string)
    field(:token_created_at, :utc_datetime_usec)
    belongs_to(:user, Config.user_schema())

    timestamps()
  end

  use Coherence.Rememberable

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  @rememberable_fields ~w[series_hash token_hash token_created_at user_id]a
  @spec changeset(Ecto.Schema.t(), Map.t()) :: Ecto.Changeset.t()
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @rememberable_fields)
    |> validate_required(@rememberable_fields)
  end

  @doc """
  Creates a changeset for a new schema
  """
  @spec new_changeset(Map.t()) :: Ecto.Changeset.t()
  def new_changeset(params \\ %{}) do
    changeset(%Rememberable{}, params)
  end
end
