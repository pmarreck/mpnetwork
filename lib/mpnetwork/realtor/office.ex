defmodule Mpnetwork.Realtor.Office do
  use Mpnetwork.Ecto.Schema

  import Mpnetwork.Utils.Regexen
  alias Mpnetwork.Realtor.Office

  schema "offices" do
    field(:name, :string)
    field(:address, :string)
    field(:city, :string)
    field(:state, :string)
    field(:zip, :string)
    field(:phone, :string)
    field(:url, :string)

    timestamps()
  end

  @doc false
  def changeset(%Office{} = office, attrs) do
    # added by migration 20170828180917
    office
    |> cast(attrs, [:name, :address, :city, :state, :zip, :phone, :url])
    |> validate_required([:name])
    |> validate_format(:url, url_regex())
    |> validate_length(:name, max: 255, count: :codepoints)
    |> validate_length(:address, max: 255, count: :codepoints)
    |> validate_length(:city, max: 255, count: :codepoints)
    |> validate_length(:state, max: 2, count: :codepoints)
    |> validate_length(:zip, max: 10, count: :codepoints)
    |> validate_length(:phone, max: 16, count: :codepoints)
    |> validate_length(:url, max: 255, count: :codepoints)
    |> unique_constraint(:name, name: :offices_name_address_index)
  end
end
