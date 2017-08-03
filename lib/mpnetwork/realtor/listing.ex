defmodule Mpnetwork.Realtor.Listing do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Realtor.Listing


  schema "listings" do
    # field :user_id, :id
    belongs_to :user, Mpnetwork.User
    field :draft, :boolean, default: false
    field :for_sale, :boolean, default: false
    field :for_rent, :boolean, default: false
    field :class_type, ClassTypeEnum
    field :listing_status_type, ListingStatusTypeEnum
    field :basement_type, BasementTypeEnum
    field :expires_on, :date
    field :state, :string
    field :new_construction, :boolean, default: false
    field :fios_available, :boolean, default: false
    field :tax_rate_code_area, :integer
    field :prop_tax_usd, :integer
    field :num_skylights, :integer
    field :lot_size, :string
    field :attached_garage, :boolean, default: false
    field :zip, :string
    field :ext_urls, {:array, :string}
    field :visible_on, :date
    field :city, :string
    field :num_fireplaces, :integer
    field :modern_kitchen_countertops, :boolean, default: false
    field :deck, :boolean, default: false
    field :central_air, :boolean, default: false
    field :stories, :integer
    field :num_half_baths, :integer
    field :year_built, :integer
    field :pool, :boolean, default: false
    field :mls_source_id, :integer
    field :security_system, :boolean, default: false
    field :sq_ft, :integer
    field :studio, :boolean, default: false
    field :cellular_coverage_quality, :integer
    field :hot_tub, :boolean, default: false
    field :basement, :boolean, default: false
    field :price_usd, :integer
    field :remarks, :string
    field :parking_spaces, :integer
    field :description, :string
    field :num_bedrooms, :integer
    field :high_speed_internet_available, :boolean, default: false
    field :patio, :boolean, default: false
    field :address, :string
    field :num_garages, :integer
    field :num_baths, :integer
    field :central_vac, :boolean, default: false
    field :eef_led_lighting, :boolean, default: false
    has_many :price_history, Mpnetwork.Listing.PriceHistory, on_delete: :delete_all
    has_many :attachments, Mpnetwork.Listing.Attachment, on_delete: :delete_all

    timestamps()
  end

  @doc """
    Relaxed requireds for listing attributes in "draft" status.
    That was easy...
  """
  def changeset(%Listing{} = listing, %{"draft" => "true"} = attrs) do
    listing
    |> casts(attrs)
    |> validate_required([:user_id, :address])
    |> constraints
  end

  def changeset(%Listing{} = listing, attrs) do
    listing
    |> casts(attrs)
    |> validate_required([:user_id, :draft, :for_sale, :for_rent, :address, :city, :state, :zip, :price_usd, :studio, :num_bedrooms, :num_baths, :num_half_baths, :sq_ft, :lot_size, :year_built, :stories, :basement, :num_fireplaces, :parking_spaces, :num_garages, :attached_garage, :new_construction, :prop_tax_usd, :patio, :deck, :pool, :hot_tub, :num_skylights, :central_air, :central_vac, :security_system, :fios_available, :high_speed_internet_available, :modern_kitchen_countertops, :eef_led_lighting, :visible_on, :expires_on])
    |> constraints
  end

  defp constraints(listing) do
    listing
    |> validate_inclusion(:cellular_coverage_quality, 0..5)
    |> validate_inclusion(:price_usd, 0..2147483647, message: "Price must currently be between $0 and $2,147,483,647. (If you need to bump this limit, speak to the site developer. Also, nice job!)")
  end

  defp casts(%Listing{} = listing, attrs) do
    listing
    |> cast(attrs, [:user_id, :draft, :for_sale, :for_rent, :description, :address, :city, :state, :zip, :price_usd, :studio, :num_bedrooms, :num_baths, :num_half_baths, :sq_ft, :lot_size, :year_built, :stories, :basement, :num_fireplaces, :parking_spaces, :mls_source_id, :num_garages, :attached_garage, :new_construction, :tax_rate_code_area, :prop_tax_usd, :patio, :deck, :pool, :hot_tub, :num_skylights, :central_air, :central_vac, :security_system, :fios_available, :high_speed_internet_available, :modern_kitchen_countertops, :cellular_coverage_quality, :eef_led_lighting, :ext_urls, :remarks, :visible_on, :expires_on])
    |> foreign_key_constraint(:user_id)
  end

end
