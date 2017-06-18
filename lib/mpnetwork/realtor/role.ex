defmodule Mpnetwork.Realtor.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Realtor.Role

  schema "roles" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
