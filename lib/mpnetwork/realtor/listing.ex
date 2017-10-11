defmodule Mpnetwork.Realtor.Listing do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Realtor.Listing


  schema "listings" do
    field :draft, :boolean
    field :for_sale, :boolean
    field :for_rent, :boolean
    field :class_type, ClassTypeEnum
    field :studio, :boolean
    field :address, :string
    field :city, :string
    field :state, :string
    field :zip, :string
    field :district, :string
    field :section_num, :integer
    field :block_num, :integer
    field :lot_num, :integer
    field :association, :string
    field :neighborhood, :string
    field :schools, :string
    field :zoning, :string
    field :corner, :boolean
    field :cross_street, :string
    field :cul_de_sac, :boolean
    field :waterfront, :boolean
    field :water_frontage_ft, :integer
    field :bulkhead_ft, :integer
    field :waterfront_type, WaterfrontTypeEnum
    field :waterview, :boolean
    field :bulkhead, :boolean
    field :dock_rights, :boolean
    field :beach_rights, :boolean
    field :adult_comm, :boolean
    field :gated_comm, :boolean
    field :front_exposure_type, CompassPointEnum
    field :price_usd, :integer
    field :prior_price_usd, :integer
    field :original_price_usd, :integer
    field :tax_rate_code_area, :integer
    field :prop_tax_usd, :integer
    field :vill_tax_usd, :integer
    field :visible_on, :date
    field :star_deduc_usd, :integer
    field :expires_on, :date
    field :listing_status_type, ListingStatusTypeEnum
    field :style_type, StyleTypeEnum
    field :stories, :integer
    field :num_rooms, :integer
    field :num_bedrooms, :integer
    field :num_baths, :integer
    field :num_half_baths, :integer
    field :num_families, :integer
    field :att_type, AttachmentTypeEnum
    field :num_kitchens, :integer
    field :eat_in_kitchen, :boolean
    field :dining_room_type, DiningRoomTypeEnum
    field :den, :boolean
    field :office, :boolean
    field :attic, :boolean
    field :mbr_first_fl, :boolean
    field :permit, :string
    field :handicap_access, :boolean
    field :handicap_access_desc, :string
    field :sq_ft, :integer
    field :basement, :boolean
    field :basement_type, BasementTypeEnum
    field :finished_basement, :boolean
    field :num_fireplaces, :integer
    field :w_w_carpet, :boolean
    field :wood_floors, :boolean
    field :year_built, :integer
    field :new_construction, :boolean
    field :num_skylights, :integer
    field :appearance, :string
    field :basement_desc, :string
    field :first_fl_desc, :string
    field :second_fl_desc, :string
    field :third_fl_desc, :string
    field :siding_desc, :string
    field :construction, :string
    field :num_garages, :integer
    field :num_half_garages, :integer
    field :attached_garage, :boolean
    field :driveway, :string
    field :parking_spaces, :integer
    field :deck, :boolean
    field :deck_type, DeckTypeEnum
    field :patio, :boolean
    field :patio_type, PatioTypeEnum
    field :porch, :boolean
    field :porch_type, PorchTypeEnum
    field :pool, :boolean
    field :pool_type, PoolTypeEnum
    field :hot_tub, :boolean
    field :ing_sprinks, :boolean
    field :tennis_ct, :boolean
    field :tennis_ct_desc, :string
    field :equestrian, :boolean
    field :lot_size, :string
    field :lot_sqft, :integer
    field :building_size_sqft, :integer
    field :num_stoves, :integer
    field :num_refrigs, :integer
    field :num_washers, :integer
    field :num_dryers, :integer
    field :num_dishwashers, :integer
    field :fuel_type, FuelTypeEnum
    field :heating_type, HeatingTypeEnum
    field :heat_num_zones, :integer
    field :central_air, :boolean
    field :sewer, :boolean
    field :sewage_type, SewageTypeEnum
    field :sep_hw_heater, :boolean
    field :sep_hw_heater_type, SepHwHeaterTypeEnum
    field :ac_num_zones, :integer
    field :water_type, WaterTypeEnum
    field :energy_eff, :boolean
    field :eef_led_lighting, :boolean
    field :eef_energy_star_stove, :boolean
    field :eef_energy_star_refrigerator, :boolean
    field :eef_energy_star_dishwasher, :boolean
    field :eef_energy_star_washer, :boolean
    field :eef_energy_star_dryer, :boolean
    field :eef_energy_star_water_heater, :boolean
    field :eef_geothermal_water_heater, :boolean
    field :eef_solar_water_heater, :boolean
    field :eef_tankless_water_heater, :boolean
    field :eef_double_pane_windows, :boolean
    field :eef_insulated_windows, :boolean
    field :eef_tinted_windows, :boolean
    field :eef_triple_pane_windows, :boolean
    field :eef_energy_star_windows, :boolean
    field :eef_storm_doors, :boolean
    field :eef_insulated_doors, :boolean
    field :eef_energy_star_doors, :boolean
    field :eef_foam_insulation, :boolean
    field :eef_cellulose_insulation, :boolean
    field :eef_blown_insulation, :boolean
    field :eef_programmable_thermostat, :boolean
    field :eef_low_flow_showers_fixtures, :boolean
    field :eef_low_flow_dual_flush_toilet, :boolean
    field :eef_gray_water_system, :boolean
    field :eef_energy_star_furnace, :boolean
    field :eef_geothermal_heating, :boolean
    field :eef_energy_star_ac, :boolean
    field :eef_energy_star_cac, :boolean
    field :eef_geothermal_ac, :boolean
    field :eef_solar_ac, :boolean
    field :eef_solar_panels, :boolean
    field :eef_solar_pool_cover, :boolean
    field :eef_windmill, :boolean
    field :green_certified, :boolean
    field :green_cert_type, GreenCertTypeEnum
    field :green_cert_year, :integer
    field :central_vac, :boolean
    field :security_system, :boolean
    field :fios_available, :boolean
    field :high_speed_internet_available, :boolean
    field :modern_kitchen_countertops, :boolean
    field :cellular_coverage_quality, :integer
    field :owner_name, :string
    field :status_showing_phone, :string
    belongs_to :broker, Mpnetwork.Realtor.Office, foreign_key: :broker_id
    field :broker_agent_owned, :boolean
    belongs_to :user, Mpnetwork.User
    field :listing_agent_phone, :string
    belongs_to :colisting_agent, Mpnetwork.User
    field :colisting_agent_phone, :string
    field :seller_agency_comp, :integer
    field :buyer_agency_comp, :integer
    field :broker_agency_comp, :integer
    field :listing_broker_comp_rental, :integer
    field :buyer_exclusions, :boolean
    field :negotiate_direct, :boolean
    field :offers_presentable, :boolean
    field :occupancy, :string
    field :show_instr, :string
    field :lockbox, :boolean
    field :owner_financing, :boolean
    field :remarks, :string #actually :text
    field :directions, :string #actually :text
    field :description, :string #actually :text
    field :rental_income_usd, :integer
    field :also_for_rent, :boolean
    field :rental_price_usd, :integer
    field :personal_prop_exclusions, :string
    field :mls_source_id, :integer
    field :reo, :boolean
    field :short_sale, :boolean
    field :ext_urls, {:array, :string}
    field :next_broker_oh_start_at, :naive_datetime
    field :next_broker_oh_end_at, :naive_datetime
    field :next_broker_oh_note, :string #actually :text
    field :next_cust_oh_start_at, :naive_datetime
    field :next_cust_oh_end_at, :naive_datetime
    field :next_cust_oh_note, :string #actually :text
    field :selling_agent_name, :string
    # has_many :price_history, Mpnetwork.Listing.PriceHistory, on_delete: :delete_all
    has_many :attachments, Mpnetwork.Listing.Attachment, on_delete: :delete_all

    timestamps()
  end

  @datetime_order_constraint_violation_message "Start datetime needs to be earlier than end datetime"
  @datetime_sameday_constraint_violation_message "End day must be same as start day for one-day events"
  defp validate_db_datetime_constraints(changeset) do
    changeset
    |> check_constraint(:next_broker_oh_start_at, name: "broker_oh_start_earlier_than_end", message: @datetime_order_constraint_violation_message)
    |> check_constraint(:next_broker_oh_end_at, name: "broker_oh_start_earlier_than_end", message: @datetime_order_constraint_violation_message)
    |> check_constraint(:next_cust_oh_start_at, name: "cust_oh_start_earlier_than_end", message: @datetime_order_constraint_violation_message)
    |> check_constraint(:next_cust_oh_end_at, name: "cust_oh_start_earlier_than_end", message: @datetime_order_constraint_violation_message)
    |> check_constraint(:visible_on, name: "listing_date_earlier_than_expiry_date", message: @datetime_order_constraint_violation_message)
    |> check_constraint(:expires_on, name: "listing_date_earlier_than_expiry_date", message: @datetime_order_constraint_violation_message)
    |> check_constraint(:next_broker_oh_start_at, name: "broker_oh_datetimes_same_day", message: @datetime_sameday_constraint_violation_message)
    |> check_constraint(:next_broker_oh_end_at, name: "broker_oh_datetimes_same_day", message: @datetime_sameday_constraint_violation_message)
    |> check_constraint(:next_cust_oh_start_at, name: "cust_oh_datetimes_same_day", message: @datetime_sameday_constraint_violation_message)
    |> check_constraint(:next_cust_oh_end_at, name: "cust_oh_datetimes_same_day", message: @datetime_sameday_constraint_violation_message)
   end

  defp validate_consecutive_datetimes(changeset, {field_first, field_last}) do
    earlier = get_field(changeset, field_first)
    hopefully_later = get_field(changeset, field_last)
    if earlier && hopefully_later do
      case hopefully_later > earlier do
        true -> changeset
        _    -> add_error(changeset, field_first, @datetime_order_constraint_violation_message)
                |> add_error(field_last, @datetime_order_constraint_violation_message)
      end
    else
      changeset
    end
  end

  defp validate_happens_on_same_day(changeset, {field_first, field_last}) do
    earlier = get_field(changeset, field_first)
    hsd = get_field(changeset, field_last) # hsd = "hopefully same day"
    if earlier && hsd do
      sameday = {earlier.year, earlier.month, earlier.day} == {hsd.year, hsd.month, hsd.day}
      case sameday do
        true -> changeset
        _    -> add_error(changeset, field_last, @datetime_sameday_constraint_violation_message)
      end
    else
      changeset
    end
  end

  @doc """
    Relaxed requireds for listing attributes in "draft" status.
    That was easy...
  """
  def changeset(%Listing{} = listing, %{"draft" => "true"} = attrs) do
    listing
    |> casts(attrs)
    |> validate_required([:user_id, :broker_id, :address])
    |> constraints
  end

  def changeset(%Listing{} = listing, attrs) do
    listing
    |> casts(attrs)
    |> validate_required([:user_id, :broker_id, :draft, :for_sale, :for_rent, :address, :city, :state, :zip, :price_usd, :num_bedrooms, :num_baths, :num_half_baths, :year_built, :basement, :visible_on, :expires_on])
    |> constraints
  end

  defp constraints(listing) do
    this_year = Timex.today.year
    listing
    |> validate_inclusion(:cellular_coverage_quality, 0..5)
    |> validate_inclusion(:price_usd, 0..2147483647, message: "Prices must currently be between $0 and $2,147,483,647. (If you need to bump this limit, speak to the site developer. Also, nice job!)")
    |> validate_inclusion(:prior_price_usd, 0..2147483647, message: "Prices must currently be between $0 and $2,147,483,647.")
    |> validate_inclusion(:original_price_usd, 0..2147483647, message: "Prices must currently be between $0 and $2,147,483,647.")
    |> validate_inclusion(:prop_tax_usd, 0..2147483647, message: "Prices must currently be between $0 and $2,147,483,647.")
    |> validate_inclusion(:vill_tax_usd, 0..2147483647, message: "Prices must currently be between $0 and $2,147,483,647.")
    |> validate_inclusion(:star_deduc_usd, 0..2147483647, message: "Prices must currently be between $0 and $2,147,483,647.")
    |> validate_inclusion(:rental_income_usd, 0..2147483647, message: "Prices must currently be between $0 and $2,147,483,647.")
    |> validate_inclusion(:rental_price_usd, 0..2147483647, message: "Prices must currently be between $0 and $2,147,483,647.")
    |> validate_inclusion(:year_built, 1600..this_year, message: "Year built must currently be between 1600 and #{this_year}.")
    |> validate_inclusion(:seller_agency_comp, 0..30, message: "Comp points must currently be between 0 and 30")
    |> validate_inclusion(:buyer_agency_comp, 0..30, message: "Comp points must currently be between 0 and 30")
    |> validate_inclusion(:broker_agency_comp, 0..30, message: "Comp points must currently be between 0 and 30")
    |> validate_number(:water_frontage_ft, greater_than_or_equal_to: 0)
    |> validate_number(:bulkhead_ft, greater_than_or_equal_to: 0)
    |> validate_number(:num_rooms, greater_than_or_equal_to: 0)
    |> validate_number(:num_bedrooms, greater_than_or_equal_to: 0)
    |> validate_number(:num_baths, greater_than_or_equal_to: 0)
    |> validate_number(:num_half_baths, greater_than_or_equal_to: 0)
    |> validate_number(:num_families, greater_than_or_equal_to: 0)
    |> validate_number(:num_kitchens, greater_than_or_equal_to: 0)
    |> validate_number(:num_fireplaces, greater_than_or_equal_to: 0)
    |> validate_number(:num_skylights, greater_than_or_equal_to: 0)
    |> validate_number(:num_garages, greater_than_or_equal_to: 0)
    |> validate_number(:num_half_garages, greater_than_or_equal_to: 0)
    |> validate_number(:parking_spaces, greater_than_or_equal_to: 0)
    |> validate_number(:lot_sqft, greater_than_or_equal_to: 0)
    |> validate_number(:building_size_sqft, greater_than_or_equal_to: 0)
    |> validate_number(:num_stoves, greater_than_or_equal_to: 0)
    |> validate_number(:num_refrigs, greater_than_or_equal_to: 0)
    |> validate_number(:num_washers, greater_than_or_equal_to: 0)
    |> validate_number(:num_dryers, greater_than_or_equal_to: 0)
    |> validate_number(:num_dishwashers, greater_than_or_equal_to: 0)
    |> validate_number(:heat_num_zones, greater_than_or_equal_to: 0)
    |> validate_number(:ac_num_zones, greater_than_or_equal_to: 0)
    |> validate_db_datetime_constraints()
    |> validate_consecutive_datetimes({:next_broker_oh_start_at, :next_broker_oh_end_at})
    |> validate_consecutive_datetimes({:next_cust_oh_start_at, :next_cust_oh_end_at})
    |> validate_consecutive_datetimes({:visible_on, :expires_on})
    |> validate_happens_on_same_day({:next_broker_oh_start_at, :next_broker_oh_end_at})
    |> validate_happens_on_same_day({:next_cust_oh_start_at, :next_cust_oh_end_at})
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:broker_id)
  end

  defp casts(%Listing{} = listing, attrs) do
    listing
    |> cast(attrs, [
      :draft,
      :for_sale,
      :for_rent,
      :class_type,
      :studio,
      :address,
      :city,
      :state,
      :zip,
      :district,
      :section_num,
      :block_num,
      :lot_num,
      :association,
      :neighborhood,
      :schools,
      :zoning,
      :corner,
      :cross_street,
      :cul_de_sac,
      :waterfront,
      :water_frontage_ft,
      :bulkhead_ft,
      :waterfront_type,
      :waterview,
      :bulkhead,
      :dock_rights,
      :beach_rights,
      :adult_comm,
      :gated_comm,
      :front_exposure_type,
      :price_usd,
      :prior_price_usd,
      :original_price_usd,
      :tax_rate_code_area,
      :prop_tax_usd,
      :vill_tax_usd,
      :visible_on,
      :star_deduc_usd,
      :expires_on,
      :listing_status_type,
      :style_type,
      :stories,
      :num_rooms,
      :num_bedrooms,
      :num_baths,
      :num_half_baths,
      :num_families,
      :att_type,
      :num_kitchens,
      :eat_in_kitchen,
      :dining_room_type,
      :den,
      :office,
      :attic,
      :mbr_first_fl,
      :permit,
      :handicap_access,
      :handicap_access_desc,
      :sq_ft,
      :basement,
      :basement_type,
      :finished_basement,
      :num_fireplaces,
      :w_w_carpet,
      :wood_floors,
      :year_built,
      :new_construction,
      :num_skylights,
      :appearance,
      :basement_desc,
      :first_fl_desc,
      :second_fl_desc,
      :third_fl_desc,
      :siding_desc,
      :construction,
      :num_garages,
      :num_half_garages,
      :attached_garage,
      :driveway,
      :parking_spaces,
      :deck,
      :deck_type,
      :patio,
      :patio_type,
      :porch,
      :porch_type,
      :pool,
      :pool_type,
      :hot_tub,
      :ing_sprinks,
      :tennis_ct,
      :tennis_ct_desc,
      :equestrian,
      :lot_size,
      :lot_sqft,
      :building_size_sqft,
      :num_stoves,
      :num_refrigs,
      :num_washers,
      :num_dryers,
      :num_dishwashers,
      :fuel_type,
      :heating_type,
      :heat_num_zones,
      :central_air,
      :sewer,
      :sewage_type,
      :sep_hw_heater,
      :sep_hw_heater_type,
      :ac_num_zones,
      :water_type,
      :energy_eff,
      :eef_led_lighting,
      :eef_energy_star_stove,
      :eef_energy_star_refrigerator,
      :eef_energy_star_dishwasher,
      :eef_energy_star_washer,
      :eef_energy_star_dryer,
      :eef_energy_star_water_heater,
      :eef_geothermal_water_heater,
      :eef_solar_water_heater,
      :eef_tankless_water_heater,
      :eef_double_pane_windows,
      :eef_insulated_windows,
      :eef_tinted_windows,
      :eef_triple_pane_windows,
      :eef_energy_star_windows,
      :eef_storm_doors,
      :eef_insulated_doors,
      :eef_energy_star_doors,
      :eef_foam_insulation,
      :eef_cellulose_insulation,
      :eef_blown_insulation,
      :eef_programmable_thermostat,
      :eef_low_flow_showers_fixtures,
      :eef_low_flow_dual_flush_toilet,
      :eef_gray_water_system,
      :eef_energy_star_furnace,
      :eef_geothermal_heating,
      :eef_energy_star_ac,
      :eef_energy_star_cac,
      :eef_geothermal_ac,
      :eef_solar_ac,
      :eef_solar_panels,
      :eef_solar_pool_cover,
      :eef_windmill,
      :green_certified,
      :green_cert_type,
      :green_cert_year,
      :central_vac,
      :security_system,
      :fios_available,
      :high_speed_internet_available,
      :modern_kitchen_countertops,
      :cellular_coverage_quality,
      :owner_name,
      :status_showing_phone,
      :broker_id,
      :broker_agent_owned,
      :user_id,
      :listing_agent_phone,
      :colisting_agent_id,
      :colisting_agent_phone,
      :seller_agency_comp,
      :buyer_agency_comp,
      :broker_agency_comp,
      :listing_broker_comp_rental,
      :buyer_exclusions,
      :negotiate_direct,
      :offers_presentable,
      :occupancy,
      :show_instr,
      :lockbox,
      :owner_financing,
      :remarks,
      :directions,
      :description,
      :rental_income_usd,
      :also_for_rent,
      :rental_price_usd,
      :personal_prop_exclusions,
      :mls_source_id,
      :reo,
      :short_sale,
      :ext_urls,
      :next_broker_oh_start_at,
      :next_broker_oh_end_at,
      :next_broker_oh_note,
      :next_cust_oh_start_at,
      :next_cust_oh_end_at,
      :next_cust_oh_note,
      :selling_agent_name
    ])
  end

end
