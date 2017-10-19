defmodule Mpnetwork.Realtor.Office do
  use Ecto.Schema
  import Ecto.Changeset
  import Mpnetwork.Utils.Regexen
  alias Mpnetwork.Realtor.Office


  schema "offices" do
    field :name, :string
    field :address, :string
    field :city, :string
    field :state, :string
    field :zip, :string
    field :phone, :string
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(%Office{} = office, attrs) do
    office
    |> cast(attrs, [:name, :address, :city, :state, :zip, :phone, :url])
    |> validate_required([:name])
    |> validate_format(:url, url_regex())
    |> unique_constraint(:name, name: :offices_name_address_index) # added by migration 20170828180917
  end
end
