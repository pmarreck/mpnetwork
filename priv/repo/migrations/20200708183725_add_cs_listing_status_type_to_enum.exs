defmodule Mpnetwork.CurrentSchemaDef do

  # note that if you add to these later or change the ranks, you'll have to rerun a similar migration

  def schema_state(%{} = overridden_state \\ %{}) do
    initial_state = %{
      fulltext_searchable_fields: fulltext_searchable_fields(),
      boolean_text_searchable_fields: boolean_text_searchable_fields(),
      enum_class_types: enum_class_types(),
      enum_style_types: enum_style_types(),
      enum_green_cert_types: enum_green_cert_types(),
      enum_listing_status_types_for_search: enum_listing_status_types_for_search(),
      enum_listing_status_types_int_bin: enum_listing_status_types_int_bin(),
      enum_listing_status_types_for_priority_search: enum_listing_status_types_for_priority_search(),
      foreign_key_searchable_fields: foreign_key_searchable_fields(),
      ordinal_number_searchable_fields: ordinal_number_searchable_fields(),
      other_reindex_forcing_fields: other_reindex_forcing_fields(),
    } |> Map.merge(overridden_state)
    # the rest of these are key-values that depend on already-overridden values above
    initial_state = Map.merge(initial_state, %{
      enum_text_searchable_fields: [
        class_type: initial_state.enum_class_types,
        style_type: initial_state.enum_style_types,
        green_cert_type: initial_state.enum_green_cert_types,
        listing_status_type: initial_state.enum_listing_status_types_for_search
      ],
      higher_ranked_enum_searchable_fields: [
        listing_status_type: initial_state.enum_listing_status_types_for_priority_search
      ]
    })
    initial_state = Map.merge(initial_state, %{
      all_indexable_fields: (initial_state.foreign_key_searchable_fields ++
        initial_state.fulltext_searchable_fields ++
        initial_state.boolean_text_searchable_fields ++
        initial_state.enum_text_searchable_fields ++
        initial_state.ordinal_number_searchable_fields ++
        initial_state.other_reindex_forcing_fields
      )
    })
    initial_state
  end

  # Computed by calling EnumMaps.listing_status_types_int_bin() at the time this migration is written
  def enum_listing_status_types_int_bin do
    ["CS", "NEW", "FS", "EXT", "UC", "CL", "PC", "WR", "TOM", "EXP"]
  end

  def fulltext_searchable_fields do
    [
      address: "A",
      city: "B",
      state: "B",
      zip: "B",
      description: "C",
      directions: "D",
      realtor_remarks: "C",
      round_robin_remarks: "C",
      association: "C",
      neighborhood: "C",
      schools: "B",
      zoning: "C",
      district: "C",
      construction: "C",
      siding_desc: "C",
      appearance: "C",
      basement_desc: "C",
      first_fl_desc: "C",
      second_fl_desc: "C",
      third_fl_desc: "C",
      cross_street: "C",
      owner_name: "C",
      addl_listing_agent_name: "C",
      addl_listing_broker_name: "C",
      selling_agent_name: "C",
      selling_broker_name: "C"
    ]
  end

  def boolean_text_searchable_fields do
    [
      draft: "is_draft draft",
      studio: "is_studio studio",
      for_sale: "is_for_sale for sale",
      for_rent: "is_for_rent for rent",
      basement: "has_basement basement",
      attached_garage: "has_attached_garage attached garage",
      new_construction: "is_new_construction new construction",
      patio: "has_patio patio",
      deck: "has_deck deck",
      pool: "has_pool pool",
      hot_tub: "has_hot_tub hot tub",
      porch: "has_porch porch",
      central_air: "has_central_air central air",
      central_vac: "has_central_vac central vac",
      security_system: "has_security_system security system",
      fios_available: "has_fios_available has_fios FIOS",
      high_speed_internet_available:
        "has_high_speed_internet_available has_high_speed_internet high speed internet",
      modern_kitchen_countertops:
        "has_modern_kitchen_countertops has_granite_countertops modern kitchen countertops",
      eef_led_lighting: "has_eef_led_lighting has_led LED lighting",
      tennis_ct: "has_tennis_ct tennis court",
      mbr_first_fl: "has_mbr_first_fl master bedroom first floor",
      office: "has_office office",
      den: "has_den den",
      attic: "has_attic attic",
      finished_basement: "has_finished_basement finished basement",
      w_w_carpet: "has_w_w_carpet wall to wall carpet",
      wood_floors: "has_wood_floors has_wood_flooring wood floors wood flooring",
      dock_rights: "has_dock_rights dock rights",
      beach_rights: "has_beach_rights beach rights",
      waterfront: "has_waterfront waterfront",
      waterview: "has_waterview waterview",
      bulkhead: "has_bulkhead bulkhead",
      cul_de_sac: "is_cul_de_sac cul de sac",
      corner: "is_corner corner",
      adult_comm: "is_adult_comm adult community",
      gated_comm: "is_gated_comm gated community",
      eat_in_kitchen: "has_eat_in_kitchen eat-in kitchen",
      energy_eff: "is_energy_eff is_energy_efficient energy efficient",
      green_certified: "is_green_certified is_green has_green green certified",
      eef_geothermal_heating:
        "has_eef_geothermal_heating is_geothermal has_geothermal geothermal heating",
      eef_solar_panels: "has_eef_solar_panels is_solar has_solar solar",
      eef_windmill: "has_eef_windmill has_windmill windmill",
      ing_sprinks: "has_ing_sprinks inground sprinklers",
      short_sale: "is_short_sale short sale",
      reo: "is_reo REO",
      handicap_access: "has_handicapped has_handicap_access has_handicap handicapped handicap",
      equestrian: "is_equestrian has_horse stables equestrian horse",
      also_for_rent: "is_for_rent is_also_for_rent for rent",
      buyer_exclusions: "has_buyer_exclusions buyer exclusions",
      broker_agent_owned: "is_broker_agent_owned broker/agent broker agent owned",
      pets_ok: "has_pets_ok pets ok",
      smoking_ok: "has_smoking_ok smoking ok"
    ]
  end

  # taken from running Mpnetwork.EnumMaps.class_types()
  # at the time this migration is written
  def enum_class_types do
    [
      residential: "Residential",
      condo: "Condo",
      co_op: "Co-op",
      hoa: "HOA",
      rental: "Rental",
      land: "Land",
      commercial_industrial: "Commercial/Industrial"
    ]
  end

  # taken from running Mpnetwork.EnumMaps.style_types()
  # at the time this migration is written
  def enum_style_types do
    [
      "2_story": "2 Story",
      antique_hist: "Antique/Hist",
      barn: "Barn",
      bungalow: "Bungalow",
      cape: "Cape",
      colonial: "Colonial",
      contemporary: "Contemporary",
      cottage: "Cottage",
      duplex: "Duplex",
      estate: "Estate",
      exp_cape: "Exp Cape",
      exp_ranch: "Exp Ranch",
      farm_ranch: "Farm Ranch",
      farmhouse: "Farmhouse",
      hi_ranch: "Hi Ranch",
      houseboat: "Houseboat",
      mediterranean: "Mediterranean",
      mobile_home: "Mobile Home",
      modern: "Modern",
      nantucket: "Nantucket",
      postmodern: "Postmodern",
      prewar: "Prewar",
      raised_ranch: "Raised Ranch",
      ranch: "Ranch",
      saltbox: "Saltbox",
      splanch: "Splanch",
      split: "Split",
      split_ranch: "Split Ranch",
      store_dwell: "Store+Dwell",
      townhouse: "Townhouse",
      traditional: "Traditional",
      tudor: "Tudor",
      victorian: "Victorian",
      other: "Other"
    ]
  end

  # taken from running Mpnetwork.EnumMaps.green_cert_types()
  # at the time this migration is written
  def enum_green_cert_types do
    [
      energy_star: "Energy Star",
      hers: "HERS",
      leed: "LEED",
      leed_gold: "LEED Gold",
      leed_silver: "LEED Silver",
      leed_platinum: "LEED Platinum"
    ]
  end

  # taken from running Mpnetwork.EnumMaps.enum_listing_status_types_for_search()
  # at the time this migration is written
  def enum_listing_status_types_for_search do
    [
      CS: "Coming Soon",
      NEW: "New",
      FS: "For Sale",
      EXT: "Extended",
      UC: "Under Contract",
      CL: "Closed Sold",
      PC: "Price Change",
      WR: "Withdrawn",
      TOM: "Temporarily Off Market",
      EXP: "Expired"
    ]
  end

  # taken from running Mpnetwork.EnumMaps.listing_status_types_for_priority_search()
  # at the time this migration is written
  def enum_listing_status_types_for_priority_search do
    [
      CS: "CS lst/CS",
      NEW: "NEW lst/NEW",
      FS: "FS lst/FS",
      EXT: "EXT lst/EXT",
      UC: "UC lst/UC",
      CL: "CL lst/CL",
      PC: "PC lst/PC",
      WR: "WR lst/WR",
      TOM: "TOM lst/TOM",
      EXP: "EXP lst/EXP"
    ]
  end

  def foreign_key_searchable_fields do
    [
      user_id: {:users, :name},
      broker_id: {:offices, :name},
      colisting_agent_id: {:users, :name}
    ]
  end

  # room, bedroom, bathroom, fireplace, skylight, garage, family, story
  def ordinal_number_searchable_fields do
    [
      num_rooms: "roo",
      num_bedrooms: "bed",
      num_baths: "bat",
      num_fireplaces: "fir",
      num_skylights: "sky",
      num_garages: "gar",
      num_families: "fam",
      stories: "sto"
    ]
  end

  # fields the updating of which should trigger a search reindex, regardless
  def other_reindex_forcing_fields do
    [
      # due to expiration state possibly changing
      expires_on: nil
    ]
  end

end

defmodule Mpnetwork.Repo.Migrations.Add_CS_ListingStatusTypeToEnum do
  @disable_ddl_transaction true # altering types cannot be done in a transaction
  use Ecto.Migration
  alias Mpnetwork.Ecto.MigrationSupport, as: MS
  alias Mpnetwork.CurrentSchemaDef, as: Schema

  # The up state is just the current schema state as defined above this migration
  @up_state Schema.schema_state()
  # The down state is any difference from the current state to the previous state.
  # In this case we're adding a new listing status "CS" so we have to remove it to get to
  # the previous schema state.
  @down_state Schema.schema_state(%{
    enum_listing_status_types_for_search: Keyword.drop(@up_state.enum_listing_status_types_for_search, [:CS]),
    enum_listing_status_types_int_bin: (@up_state.enum_listing_status_types_int_bin -- ["CS"]),
    enum_listing_status_types_for_priority_search: (@up_state.enum_listing_status_types_for_priority_search -- [{:CS, "CS lst/CS"}]),
  })

  def up do
    MS.execute_all([
      # unfortunately we'll have to temporarily drop soft-delete support on listings and then re-enable it
      MS.undo_softdelete_view_sql(:listings),
      # oh god. now I have to drop and recreate the search index updating triggers that depend on user_id
      MS.undo_search_index_trigger_sql(),
      # since we're modifying listing status, have to rebuild the search vector code
      MS.undo_search_index_function_sql(),

      # the meat
      MS.add_enum_values_and_modify_column_sql("listing_status_type", @up_state.enum_listing_status_types_int_bin, "listings", "listing_status_type"),

      MS.search_trigger_function_creation_sql(@up_state),
      MS.redo_search_index_trigger_sql(@up_state),
      MS.redo_softdelete_view_sql(:listings),
      MS.force_search_reindex_sql(@up_state)
    ])
  end

  def down do
    MS.execute_all([
      # unfortunately we'll have to temporarily drop soft-delete support on listings and then re-enable it
      MS.undo_softdelete_view_sql(:listings),
      # oh god. now I have to drop and recreate the search index updating triggers that depend on user_id
      MS.undo_search_index_trigger_sql(),
      # since we're modifying listing status, have to rebuild the search vector code
      MS.undo_search_index_function_sql(),

      # the meat
      MS.drop_enum_value_and_modify_column_sql("listing_status_type", @down_state.enum_listing_status_types_int_bin, "CS", nil, "listings", "listing_status_type"),

      MS.search_trigger_function_creation_sql(@down_state),
      MS.redo_search_index_trigger_sql(@down_state),
      MS.redo_softdelete_view_sql(:listings),
      MS.force_search_reindex_sql(@down_state)
    ])
  end

end
