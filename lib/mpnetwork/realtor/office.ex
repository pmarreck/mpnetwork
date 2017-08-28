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
    |> cast(attrs, [:name, :address, :city, :state, :zip, :phone])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :offices_name_address_index) # added by migration 20170828180917
  end
end
