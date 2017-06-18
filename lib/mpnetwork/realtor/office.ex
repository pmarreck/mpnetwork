defmodule Mpnetwork.Realtor.Office do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Realtor.Office

  schema "offices" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Office{} = office, attrs) do
    office
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
