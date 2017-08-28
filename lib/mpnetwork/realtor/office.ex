defmodule Mpnetwork.Realtor.Office do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Realtor.Office

  schema "offices" do
    field :name, :string
    field :address, :string
    field :city, :string
    field :state, :string
    field :zip, :string
    field :phone, :string

    timestamps()
  end

  @doc false
  def changeset(%Office{} = office, attrs) do
    office
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
