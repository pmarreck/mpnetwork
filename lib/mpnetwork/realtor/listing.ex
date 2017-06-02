defmodule Mpnetwork.Realtor.Listing do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Realtor.Listing


  schema "listings" do
    field :expires_on, :date
    field :state, :string
    field :new_construction, :boolean, default: false
    field :fios_available, :boolean, default: false
    field :tax_rate_code_area, :integer
    field :total_annual_property_taxes_usd, :integer
    field :num_skylights, :integer
    field :lot_size_acre_cents, :integer
    field :attached_garage, :boolean, default: false
    field :for_rent, :boolean, default: false
    field :zip, :string
    field :ext_url, :string
    field :visible_on, :date
    field :city, :string
    field :fireplaces, :integer
    field :new_appliances, :boolean, default: false
    field :modern_kitchen_countertops, :boolean, default: false
    field :deck, :boolean, default: false
    field :for_sale, :boolean, default: false
    field :central_air, :boolean, default: false
    field :stories, :integer
    field :num_half_baths, :integer
    field :year_built, :integer
    field :draft, :boolean, default: false
    field :pool, :boolean, default: false
    field :mls_source_id, :integer
    field :security_system, :boolean, default: false
    field :sq_ft, :integer
    field :studio, :boolean, default: false
    field :cellular_coverage_quality, :integer
    field :hot_tub, :boolean, default: false
    field :basement, :boolean, default: false
    field :price_usd, :integer
    field :special_notes, :string
    field :parking_spaces, :integer
    field :description, :string
    field :num_bedrooms, :integer
    field :high_speed_internet_available, :boolean, default: false
    field :patio, :boolean, default: false
    field :address, :string
    field :num_garages, :integer
    field :num_baths, :integer
    field :central_vac, :boolean, default: false
    field :led_lighting, :boolean, default: false
    field :user_id, :id
    field :building_type_id, :id

    timestamps()
  end

  @doc """
    Reduced requireds for listing attributes in "draft" status.
    That was easy...
  """
  def changeset(%Listing{} = listing, %{"draft" => "true"} = attrs) do
    listing
    |> casts(attrs)
    |> validate_required([:address])
  end

  def changeset(%Listing{} = listing, attrs) do
    listing
    |> casts(attrs)
    |> validate_required([:draft, :for_sale, :for_rent, :description, :address, :city, :state, :zip, :price_usd, :studio, :num_bedrooms, :num_baths, :num_half_baths, :sq_ft, :lot_size_acre_cents, :year_built, :stories, :basement, :fireplaces, :parking_spaces, :mls_source_id, :num_garages, :attached_garage, :new_construction, :tax_rate_code_area, :total_annual_property_taxes_usd, :patio, :deck, :pool, :hot_tub, :num_skylights, :central_air, :central_vac, :security_system, :fios_available, :high_speed_internet_available, :modern_kitchen_countertops, :cellular_coverage_quality, :led_lighting, :new_appliances, :ext_url, :special_notes, :visible_on, :expires_on])
  end

  defp casts(%Listing{} = listing, attrs) do
    listing
    |> cast(attrs, [:draft, :for_sale, :for_rent, :description, :address, :city, :state, :zip, :price_usd, :studio, :num_bedrooms, :num_baths, :num_half_baths, :sq_ft, :lot_size_acre_cents, :year_built, :stories, :basement, :fireplaces, :parking_spaces, :mls_source_id, :num_garages, :attached_garage, :new_construction, :tax_rate_code_area, :total_annual_property_taxes_usd, :patio, :deck, :pool, :hot_tub, :num_skylights, :central_air, :central_vac, :security_system, :fios_available, :high_speed_internet_available, :modern_kitchen_countertops, :cellular_coverage_quality, :led_lighting, :new_appliances, :ext_url, :special_notes, :visible_on, :expires_on])
  end

end