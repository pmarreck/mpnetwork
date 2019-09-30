defmodule Mpnetwork.Schema.Session do
  use Ecto.Schema

  import Ecto.Changeset

  schema "sessions" do
    field :token, :string
    field :user_type, :string
    field :user_id, :string
    field :data, Mpnetwork.Ecto.CompressedTerm
    timestamps()
  end

  @fields ~w(token user_type user_id data)a
  @required_fields ~w(token user_type user_id)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:token)
  end
end
