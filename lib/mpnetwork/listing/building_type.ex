defmodule Mpnetwork.Listing.BuildingType do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Listing.BuildingType


  schema "building_types" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%BuildingType{} = building_type, attrs) do
    building_type
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
