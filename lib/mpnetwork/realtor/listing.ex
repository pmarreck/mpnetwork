defmodule Mpnetwork.Realtor.Listing do
  use Mpnetwork.Ecto.SoftDelete.Schema
  alias Mpnetwork.Realtor.Listing

  @timestamps_opts [type: :utc_datetime_usec]

  @listing_data_fields [
    draft: :boolean,
    for_sale: :boolean,
    for_rent: :boolean,
    class_type: ClassTypeEnum,
    studio: :boolean,
    address: :string,
    city: :string,
    state: :string,
    zip: :string,
    district: :string,
    section_num: :string,
    block_num: :string,
    lot_num: :string,
    association: :string,
    neighborhood: :string,
    schools: :string,
    zoning: :string,
    corner: :boolean,
    cross_street: :string,
    cul_de_sac: :boolean,
    waterfront: :boolean,
    water_frontage_ft: :integer,
    bulkhead_ft: :integer,
    waterfront_type: WaterfrontTypeEnum,
    waterview: :boolean,
    bulkhead: :boolean,
    dock_rights: :boolean,
    beach_rights: :boolean,
    adult_comm: :boolean,
    gated_comm: :boolean,
    front_exposure_type: CompassPointEnum,
    price_usd: :integer,
    prior_price_usd: :integer,
    original_price_usd: :integer,
    tax_rate_code_area: :integer,
    prop_tax_usd: :integer,
    vill_tax_usd: :integer,
    live_at: :naive_datetime,
    star_deduc_usd: :integer,
    expires_on: :date,
    listing_status_type: ListingStatusTypeEnum,
    style_type: StyleTypeEnum,
    stories: :integer,
    num_rooms: :integer,
    num_bedrooms: :integer,
    num_baths: :integer,
    num_half_baths: :integer,
    num_families: :integer,
    att_type: AttachmentTypeEnum,
    num_kitchens: :integer,
    eat_in_kitchen: :boolean,
    dining_room_type: DiningRoomTypeEnum,
    den: :boolean,
    office: :boolean,
    attic: :boolean,
    mbr_first_fl: :boolean,
    permit: :string,
    handicap_access: :boolean,
    handicap_access_desc: :string,
    sq_ft: :integer,
    basement: :boolean,
    basement_type: BasementTypeEnum,
    finished_basement: :boolean,
    num_fireplaces: :integer,
    w_w_carpet: :boolean,
    wood_floors: :boolean,
    year_built: :integer,
    new_construction: :boolean,
    num_skylights: :integer,
    appearance: :string,
    basement_desc: :string,
    first_fl_desc: :string,
    second_fl_desc: :string,
    third_fl_desc: :string,
    siding_desc: :string,
    construction: :string,
    num_garages: :integer,
    num_half_garages: :integer,
    attached_garage: :boolean,
    driveway: :string,
    parking_spaces: :integer,
    deck: :boolean,
    deck_type: DeckTypeEnum,
    patio: :boolean,
    patio_type: PatioTypeEnum,
    porch: :boolean,
    porch_type: PorchTypeEnum,
    pool: :boolean,
    pool_type: PoolTypeEnum,
    hot_tub: :boolean,
    ing_sprinks: :boolean,
    tennis_ct: :boolean,
    tennis_ct_desc: :string,
    equestrian: :boolean,
    lot_size: :string,
    lot_sqft: :integer,
    building_size_sqft: :integer,
    num_stoves: :integer,
    num_refrigs: :integer,
    num_washers: :integer,
    num_dryers: :integer,
    num_dishwashers: :integer,
    fuel_type: FuelTypeEnum,
    heating_type: HeatingTypeEnum,
    heat_num_zones: :integer,
    central_air: :boolean,
    sewer: :boolean,
    sewage_type: SewageTypeEnum,
    sep_hw_heater: :boolean,
    sep_hw_heater_type: SepHwHeaterTypeEnum,
    ac_num_zones: :integer,
    water_type: WaterTypeEnum,
    energy_eff: :boolean,
    eef_led_lighting: :boolean,
    eef_energy_star_stove: :boolean,
    eef_energy_star_refrigerator: :boolean,
    eef_energy_star_dishwasher: :boolean,
    eef_energy_star_washer: :boolean,
    eef_energy_star_dryer: :boolean,
    eef_energy_star_water_heater: :boolean,
    eef_geothermal_water_heater: :boolean,
    eef_solar_water_heater: :boolean,
    eef_tankless_water_heater: :boolean,
    eef_double_pane_windows: :boolean,
    eef_insulated_windows: :boolean,
    eef_tinted_windows: :boolean,
    eef_triple_pane_windows: :boolean,
    eef_energy_star_windows: :boolean,
    eef_storm_doors: :boolean,
    eef_insulated_doors: :boolean,
    eef_energy_star_doors: :boolean,
    eef_foam_insulation: :boolean,
    eef_cellulose_insulation: :boolean,
    eef_blown_insulation: :boolean,
    eef_programmable_thermostat: :boolean,
    eef_low_flow_showers_fixtures: :boolean,
    eef_low_flow_dual_flush_toilet: :boolean,
    eef_gray_water_system: :boolean,
    eef_energy_star_furnace: :boolean,
    eef_geothermal_heating: :boolean,
    eef_energy_star_ac: :boolean,
    eef_energy_star_cac: :boolean,
    eef_geothermal_ac: :boolean,
    eef_solar_ac: :boolean,
    eef_solar_panels: :boolean,
    eef_solar_pool_cover: :boolean,
    eef_windmill: :boolean,
    green_certified: :boolean,
    green_cert_type: GreenCertTypeEnum,
    green_cert_year: :integer,
    central_vac: :boolean,
    security_system: :boolean,
    fios_available: :boolean,
    high_speed_internet_available: :boolean,
    modern_kitchen_countertops: :boolean,
    cellular_coverage_quality: :integer,
    owner_name: :string,
    status_showing_phone: :string,
    broker_agent_owned: :boolean,
    listing_agent_phone: :string,
    colisting_agent_phone: :string,
    seller_agency_comp: :integer,
    buyer_agency_comp: :integer,
    broker_agency_comp: :integer,
    listing_broker_comp_rental: :string,
    buyer_exclusions: :boolean,
    negotiate_direct: :boolean,
    offers_presentable: :boolean,
    occupancy: :string,
    show_instr: :string,
    lockbox: :boolean,
    owner_financing: :boolean,
    # actually :text
    realtor_remarks: :string,
    # actually :text
    round_robin_remarks: :string,
    # actually :text
    directions: :string,
    # actually :text
    description: :string,
    rental_income_usd: :integer,
    also_for_rent: :boolean,
    rental_price_usd: :integer,
    personal_prop_exclusions: :string,
    mls_source_id: :integer,
    reo: :boolean,
    short_sale: :boolean,
    ext_urls: {:array, :string},
    first_broker_oh_start_at: :naive_datetime,
    first_broker_oh_mins: :integer,
    second_broker_oh_start_at: :naive_datetime,
    second_broker_oh_mins: :integer,
    # actually :text
    next_broker_oh_note: :string,
    first_cust_oh_start_at: :naive_datetime,
    first_cust_oh_mins: :integer,
    second_cust_oh_start_at: :naive_datetime,
    second_cust_oh_mins: :integer,
    # actually :text
    next_cust_oh_note: :string,
    selling_agent_name: :string,
    selling_agent_phone: :string,
    selling_broker_name: :string,
    addl_listing_agent_name: :string,
    addl_listing_agent_phone: :string,
    addl_listing_broker_name: :string,
    uc_on: :date,
    prop_closing_on: :date,
    closed_on: :date,
    closing_price_usd: :integer,
    purchaser: :string,
    moved_from: :string,
    pets_ok: :boolean,
    smoking_ok: :boolean,
    omd_on: :date,
    commission_paid_by: :string,
    sec_dep: :string,
    deleted_at: :utc_datetime_usec,
  ]

  @listing_belongs_to_fk_fields [
    broker_id: {:broker, Mpnetwork.Realtor.Office, foreign_key: :broker_id},
    user_id: {:user, Mpnetwork.User, []},
    colisting_agent_id: {:colisting_agent, Mpnetwork.User, []}
  ]

  @listing_fields Enum.map(@listing_data_fields, fn {field, _type} -> field end)
                  ++ Enum.map(@listing_belongs_to_fk_fields, fn {field, _btattribs} -> field end)

  schema "listings" do
    @listing_data_fields
    |> Enum.each(fn {fieldname, fieldtype} ->
      field(fieldname, fieldtype)
    end)

    @listing_belongs_to_fk_fields
    |> Enum.each(fn {_fieldname, {canonical, fieldtype, btargs}} ->
      belongs_to(canonical, fieldtype, btargs)
    end)

    has_many(:attachments, Mpnetwork.Listing.Attachment, on_delete: :delete_all)

    timestamps()
  end

  @datetime_order_constraint_violation_message "Start datetime needs to be earlier than end datetime"
  defp validate_db_datetime_constraints(changeset) do
    changeset
    |> check_constraint(
      :live_at,
      name: "listing_date_earlier_than_expiry_date",
      message: @datetime_order_constraint_violation_message
    )
    |> check_constraint(
      :expires_on,
      name: "listing_date_earlier_than_expiry_date",
      message: @datetime_order_constraint_violation_message
    )
    |> check_constraint(
      :omd_on,
      name: "omd_between_now_and_15_days",
      message: "The On Market Date (OMD) must be between tomorrow and 2 weeks from now, inclusive"
    )
  end

  defp validate_consecutive_datetimes(changeset, {field_first, field_last}) do
    earlier = get_field(changeset, field_first)
    hopefully_later = get_field(changeset, field_last)

    if earlier && hopefully_later do
      case Timex.compare(earlier, hopefully_later) do
        -1 ->
          changeset

        {:error, reason} ->
          add_error(changeset, field_first, reason) |> add_error(field_last, reason)

        _ ->
          add_error(changeset, field_first, @datetime_order_constraint_violation_message)
          |> add_error(field_last, @datetime_order_constraint_violation_message)
      end
    else
      changeset
    end
  end

  defp validate_urls(changeset, nil), do: changeset
  defp validate_urls(changeset, []), do: changeset
  defp validate_urls(changeset, [""]), do: changeset

  defp validate_urls(changeset, urls) when is_list(urls) do
    import Mpnetwork.Utils.Regexen

    urls
    |> Enum.reduce(changeset, fn url, changeset ->
      case Regex.match?(url_regex(), url) do
        true -> changeset
        _ -> add_error(changeset, :ext_urls, "#{url} is not a valid URL")
      end
    end)
  end

  defp validate_required_duration_when_datetime_val_present(
         changeset,
         {_dt_fieldname, nil, _dur_fieldname, nil}
       ),
       do: changeset

  defp validate_required_duration_when_datetime_val_present(
         changeset,
         {dt_fieldname, nil, _dur_fieldname, _dur_val}
       ) do
    add_error(changeset, dt_fieldname, "Date/time required if duration is set")
  end

  defp validate_required_duration_when_datetime_val_present(
         changeset,
         {_dt_fieldname, _dt_val, dur_fieldname, nil}
       ) do
    add_error(changeset, dur_fieldname, "Duration required if date/time is set")
  end

  defp validate_required_duration_when_datetime_val_present(changeset, _), do: changeset

  defp validate_required_field_when_another_field_has_value(
         changeset,
         {_original_field, _original_view_name, nil = _original_value, _required_field,
          _required_view_name, nil = _required_value}
       ),
       do: changeset

  defp validate_required_field_when_another_field_has_value(
         changeset,
         {_original_field, original_view_name, :UC = original_value, :uc_on = required_field,
          required_view_name, nil = _required_value}
       ) do
    add_error(
      changeset,
      required_field,
      "#{required_view_name} must have a value if #{original_view_name} is set to #{
        original_value
      }"
    )
  end

  defp validate_required_field_when_another_field_has_value(
         changeset,
         {_original_field, original_view_name, :CL = original_value, :closed_on = required_field,
          required_view_name, nil = _required_value}
       ) do
    add_error(
      changeset,
      required_field,
      "#{required_view_name} must have a value if #{original_view_name} is set to #{
        original_value
      }"
    )
  end

  defp validate_required_field_when_another_field_has_value(
         changeset,
         {_original_field, original_view_name, :CL = original_value,
          :closing_price_usd = required_field, required_view_name, nil = _required_value}
       ) do
    add_error(
      changeset,
      required_field,
      "#{required_view_name} must have a value if #{original_view_name} is set to #{
        original_value
      }"
    )
  end

  defp validate_required_field_when_another_field_has_value(changeset, _), do: changeset

  defp is_not_blank(val), do: val != nil && val != ""

  defp validate_required_if_field_is_value(changeset, fields, field, value, if_error_str) do
    if get_field(changeset, field) == value do
      Enum.reduce(fields, changeset, fn field, changeset ->
        if is_not_blank(get_field(changeset, field)) do
          changeset
        else
          humanized_field = Regex.replace(~r/num_/, "#{field}", "# ")
          humanized_field = Regex.replace(~r/_/, humanized_field, " ")

          add_error(
            changeset,
            field,
            "#{humanized_field} must have a value if #{if_error_str}"
          )
        end
      end)
    else
      changeset
    end
  end

  defp validate_required_unless_field_is_value(changeset, fields, field, value, unless_error_str) do
    unless get_field(changeset, field) == value do
      Enum.reduce(fields, changeset, fn field, changeset ->
        if is_not_blank(get_field(changeset, field)) do
          changeset
        else
          humanized_field = Regex.replace(~r/num_/, "#{field}", "# ")
          humanized_field = Regex.replace(~r/_/, humanized_field, " ")

          add_error(
            changeset,
            field,
            "#{humanized_field} must have a value unless #{unless_error_str}"
          )
        end
      end)
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
    |> listing_constraints
  end

  # If a (possibly newly) non-draft listing comes through with a NEW or FS listing_status_type
  # but no live_at datetime set... Set it to now.
  # Also do this for EXT listing status.
  def changeset(
        %Listing{} = listing,
        %{"draft" => "false", "listing_status_type" => "NEW", "live_at" => ""} = attrs
      ) do
    changeset(listing, %{attrs | "live_at" => Timex.to_naive_datetime(Timex.now())})
  end

  def changeset(
        %Listing{} = listing,
        %{"draft" => "false", "listing_status_type" => "FS", "live_at" => ""} = attrs
      ) do
    changeset(listing, %{attrs | "live_at" => Timex.to_naive_datetime(Timex.now())})
  end

  def changeset(
        %Listing{} = listing,
        %{"draft" => "false", "listing_status_type" => "EXT", "live_at" => ""} = attrs
      ) do
    changeset(listing, %{attrs | "live_at" => Timex.to_naive_datetime(Timex.now())})
  end

  def changeset(%Listing{} = listing, attrs) do
    listing
    |> casts(attrs)
    |> validate_required([
      :listing_status_type,
      :user_id,
      :broker_id,
      :draft,
      :for_sale,
      :for_rent,
      :address,
      :city,
      :state,
      :zip,
      :price_usd,
      :expires_on
    ])
    |> validate_required_if_field_is_value(
      [
        :schools,
        :prop_tax_usd,
        :vill_tax_usd,
        :section_num,
        :block_num,
        :lot_num,
      ],
      :for_sale,
      true,
      "the property is For Sale"
    )
    |> validate_required_if_field_is_value(
      [
        :sec_dep,
        :commission_paid_by,
      ],
      :for_rent,
      true,
      "the property is For Rent"
    )
    |> validate_required_unless_field_is_value(
      [
        :num_bedrooms,
        :num_baths,
        :num_half_baths
      ],
      :class_type,
      :land,
      "the property class is \"Land\""
    )
    |> listing_constraints
  end

  def undelete_changeset(struct) do
    cast(struct, %{deleted_at: nil}, [:deleted_at])
  end

  defp listing_constraints(%Ecto.Changeset{} = listing) do
    this_year = Timex.today().year
    # now for text BLOBs
    listing
    |> validate_inclusion(:cellular_coverage_quality, 0..5)
    |> validate_number(:price_usd, greater_than_or_equal_to: 0)
    |> validate_number(:prior_price_usd, greater_than_or_equal_to: 0)
    |> validate_number(:original_price_usd, greater_than_or_equal_to: 0)
    |> validate_inclusion(
      :price_usd,
      0..2_147_483_647,
      message:
        "Prices must currently be between $0 and $2,147,483,647. (If you need to bump this limit, speak to the site developer. Also, nice job!)"
    )
    |> validate_inclusion(
      :closing_price_usd,
      0..2_147_483_647,
      message:
        "Prices must currently be between $0 and $2,147,483,647. (If you need to bump this limit, speak to the site developer. Also, nice job!)"
    )
    |> validate_inclusion(
      :prior_price_usd,
      0..2_147_483_647,
      message: "Prices must currently be between $0 and $2,147,483,647."
    )
    |> validate_inclusion(
      :original_price_usd,
      0..2_147_483_647,
      message: "Prices must currently be between $0 and $2,147,483,647."
    )
    |> validate_inclusion(
      :prop_tax_usd,
      0..2_147_483_647,
      message: "Prices must currently be between $0 and $2,147,483,647."
    )
    |> validate_inclusion(
      :vill_tax_usd,
      0..2_147_483_647,
      message: "Prices must currently be between $0 and $2,147,483,647."
    )
    |> validate_inclusion(
      :star_deduc_usd,
      0..2_147_483_647,
      message: "Prices must currently be between $0 and $2,147,483,647."
    )
    |> validate_inclusion(
      :rental_income_usd,
      0..2_147_483_647,
      message: "Prices must currently be between $0 and $2,147,483,647."
    )
    |> validate_inclusion(
      :rental_price_usd,
      0..2_147_483_647,
      message: "Prices must currently be between $0 and $2,147,483,647."
    )
    |> validate_inclusion(
      :year_built,
      1600..this_year,
      message: "Year built must currently be between 1600 and #{this_year}."
    )
    |> validate_inclusion(
      :seller_agency_comp,
      0..800,
      message: "Comp basis points must currently be between 0 and 800 (0% to 8%)"
    )
    |> validate_inclusion(
      :buyer_agency_comp,
      0..800,
      message: "Comp basis points must currently be between 0 and 800 (0% to 8%)"
    )
    |> validate_inclusion(
      :broker_agency_comp,
      0..800,
      message: "Comp basis points must currently be between 0 and 800 (0% to 8%)"
    )
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
    |> validate_urls(get_field(listing, :ext_urls))
    |> validate_db_datetime_constraints()
    |> validate_consecutive_datetimes({:live_at, :expires_on})
    |> validate_length(:address, max: 255, count: :codepoints)
    |> validate_length(:city, max: 255, count: :codepoints)
    |> validate_length(:state, max: 2, count: :codepoints)
    |> validate_length(:zip, max: 10, count: :codepoints)
    |> validate_length(:handicap_access_desc, max: 255, count: :codepoints)
    |> validate_length(:siding_desc, max: 255, count: :codepoints)
    |> validate_length(:section_num, max: 10, count: :codepoints)
    |> validate_length(:block_num, max: 10, count: :codepoints)
    |> validate_length(:lot_num, max: 10, count: :codepoints)
    |> validate_length(:tennis_ct_desc, max: 255, count: :codepoints)
    |> validate_length(:selling_agent_name, max: 255, count: :codepoints)
    |> validate_length(:association, max: 255, count: :codepoints)
    |> validate_length(:neighborhood, max: 255, count: :codepoints)
    |> validate_length(:schools, max: 255, count: :codepoints)
    |> validate_length(:zoning, max: 255, count: :codepoints)
    |> validate_length(:district, max: 255, count: :codepoints)
    |> validate_length(:construction, max: 255, count: :codepoints)
    |> validate_length(:appearance, max: 255, count: :codepoints)
    |> validate_length(:cross_street, max: 255, count: :codepoints)
    |> validate_length(:owner_name, max: 255, count: :codepoints)
    |> validate_length(:status_showing_phone, max: 16, count: :codepoints)
    |> validate_length(:show_instr, max: 255, count: :codepoints)
    |> validate_length(:personal_prop_exclusions, max: 255, count: :codepoints)
    |> validate_length(:permit, max: 255, count: :codepoints)
    |> validate_length(:occupancy, max: 255, count: :codepoints)
    |> validate_length(:basement_desc, max: 255, count: :codepoints)
    |> validate_length(:first_fl_desc, max: 255, count: :codepoints)
    |> validate_length(:second_fl_desc, max: 255, count: :codepoints)
    |> validate_length(:third_fl_desc, max: 255, count: :codepoints)
    |> validate_length(:lot_size, max: 255, count: :codepoints)
    |> validate_length(:driveway, max: 255, count: :codepoints)
    |> validate_length(:purchaser, max: 255, count: :codepoints)
    |> validate_length(:moved_from, max: 255, count: :codepoints)
    |> validate_length(:listing_agent_phone, max: 16, count: :codepoints)
    |> validate_length(:colisting_agent_phone, max: 16, count: :codepoints)
    |> validate_length(:addl_listing_agent_phone, max: 16, count: :codepoints)
    |> validate_length(:selling_agent_phone, max: 16, count: :codepoints)
    |> validate_length(:description, max: 4096, count: :codepoints)
    |> validate_length(:realtor_remarks, max: 4096, count: :codepoints)
    |> validate_length(:next_broker_oh_note, max: 4096, count: :codepoints)
    |> validate_length(:next_cust_oh_note, max: 4096, count: :codepoints)
    |> validate_length(:directions, max: 4096, count: :codepoints)
    |> validate_length(:round_robin_remarks, max: 4096, count: :codepoints)
    |> validate_length(:listing_broker_comp_rental, max: 4096, count: :codepoints)
    |> validate_length(:selling_broker_name, max: 400, count: :codepoints)
    |> validate_length(:addl_listing_agent_name, max: 400, count: :codepoints)
    |> validate_length(:addl_listing_broker_name, max: 400, count: :codepoints)
    |> validate_length(:commission_paid_by, max: 30, count: :codepoints)
    |> validate_length(:sec_dep, max: 30, count: :codepoints)
    |> validate_required_duration_when_datetime_val_present(
      {:first_broker_oh_start_at, get_field(listing, :first_broker_oh_start_at),
       :first_broker_oh_mins, get_field(listing, :first_broker_oh_mins)}
    )
    |> validate_required_duration_when_datetime_val_present(
      {:second_broker_oh_start_at, get_field(listing, :second_broker_oh_start_at),
       :second_broker_oh_mins, get_field(listing, :second_broker_oh_mins)}
    )
    |> validate_required_duration_when_datetime_val_present(
      {:first_cust_oh_start_at, get_field(listing, :first_cust_oh_start_at), :first_cust_oh_mins,
       get_field(listing, :first_cust_oh_mins)}
    )
    |> validate_required_duration_when_datetime_val_present(
      {:second_cust_oh_start_at, get_field(listing, :second_cust_oh_start_at),
       :second_cust_oh_mins, get_field(listing, :second_cust_oh_mins)}
    )
    |> validate_required_field_when_another_field_has_value(
      {:listing_status_type, "Listing Status", get_field(listing, :listing_status_type), :uc_on,
       "Under Contract Date", get_field(listing, :uc_on)}
    )
    |> validate_required_field_when_another_field_has_value(
      {:listing_status_type, "Listing Status", get_field(listing, :listing_status_type),
       :closed_on, "Closing/Title Transfer Date", get_field(listing, :closed_on)}
    )
    |> validate_required_field_when_another_field_has_value(
      {:listing_status_type, "Listing Status", get_field(listing, :listing_status_type),
       :closing_price_usd, "Closing Price", get_field(listing, :closing_price_usd)}
    )
    |> check_constraint(
      :omd_on,
      name: "omd_exists_if_lst_is_cs",
      message: "On Market Date (OMD) must be present when listing status is CS"
    )
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:broker_id)
  end

  defp casts(%Listing{} = listing, attrs) do
    listing
    |> cast(attrs, @listing_fields)
  end
end
