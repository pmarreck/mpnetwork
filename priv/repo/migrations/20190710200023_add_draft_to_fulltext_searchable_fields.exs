defmodule Mpnetwork.PreviousMigrations.RemoveStupidStopWords do

  # use Ecto.Migration

  alias Mpnetwork.EnumMaps

  # note that if you add to these later or change the ranks, you'll have to rerun a similar migration
  @fulltext_searchable_fields [
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
    selling_broker_name: "C",
  ]

  @boolean_text_searchable_fields [
    studio: "studio",
    for_sale: "for sale",
    for_rent: "for rent",
    basement: "basement",
    attached_garage: "attached garage",
    new_construction: "new construction",
    patio: "patio",
    deck: "deck",
    pool: "pool",
    hot_tub: "hot tub",
    porch: "porch",
    central_air: "central air",
    central_vac: "central vac",
    security_system: "security system",
    fios_available: "FIOS",
    high_speed_internet_available: "high speed internet",
    modern_kitchen_countertops: "modern kitchen countertops",
    eef_led_lighting: "LED lighting",
    tennis_ct: "tennis court",
    mbr_first_fl: "master bedroom first floor",
    office: "office",
    den: "den",
    attic: "attic",
    finished_basement: "finished basement",
    w_w_carpet: "wall to wall carpet",
    wood_floors: "wood floors",
    dock_rights: "dock rights",
    beach_rights: "beach rights",
    waterfront: "waterfront",
    waterview: "waterview",
    bulkhead: "bulkhead",
    cul_de_sac: "cul de sac",
    corner: "corner",
    adult_comm: "adult community",
    gated_comm: "gated community",
    eat_in_kitchen: "eat-in kitchen",
    energy_eff: "energy efficient",
    green_certified: "green certified",
    eef_geothermal_heating: "geothermal heating",
    eef_solar_panels: "solar",
    eef_windmill: "windmill",
    ing_sprinks: "inground sprinklers",
    short_sale: "short sale",
    reo: "REO",
    handicap_access: "handicapped handicap",
    equestrian: "horse",
    also_for_rent: "for rent",
    buyer_exclusions: "buyer exclusions",
    broker_agent_owned: "broker/agent broker agent owned",
    pets_ok: "pets ok",
    smoking_ok: "smoking ok",
  ]

  @enum_text_searchable_fields [
    class_type: EnumMaps.class_types,
    style_type: EnumMaps.style_types,
    green_cert_type: EnumMaps.green_cert_types,
    listing_status_type: EnumMaps.listing_status_types_for_search,
  ]

  # this is also an enum but will be handled specially
  @higher_ranked_enum_searchable_fields [
    listing_status_type: EnumMaps.listing_status_types_for_priority_search,
  ]

  @foreign_key_searchable_fields [
    user_id: {:users, :name},
    broker_id: {:offices, :name},
    colisting_agent_id: {:users, :name},
  ]

  # room, bedroom, bathroom, fireplace, skylight, garage, family, story
  @ordinal_number_searchable_fields [
    num_rooms: "roo",
    num_bedrooms: "bed",
    num_baths: "bat",
    num_fireplaces: "fir",
    num_skylights: "sky",
    num_garages: "gar",
    num_families: "fam",
    stories: "sto",
  ]

  # fields the updating of which should trigger a search reindex, regardless
  @other_reindex_forcing_fields [
    expires_on: nil # due to expiration state possibly changing
  ]

  @all_indexable_fields (@foreign_key_searchable_fields ++ @fulltext_searchable_fields ++ @boolean_text_searchable_fields ++ @enum_text_searchable_fields ++ @ordinal_number_searchable_fields ++ @other_reindex_forcing_fields)

  defp assemble_fulltext_searchable_fields(existing_fields, text_fields) do
    existing_fields ++ Enum.map(text_fields, fn {column, rank} ->
      "setweight(to_tsvector('english_nostop', coalesce(new.#{column},'')), '#{rank}')"
    end)
  end

  defp assemble_boolean_search_vector(existing_fields, boolean_fields) do
    existing_fields ++ Enum.map(boolean_fields, fn {column, text_if_true} ->
      "setweight(to_tsvector('english_nostop', (case when new.#{column} then '#{text_if_true}' else '' end)), 'C')"
    end)
  end

  defp assemble_enum_search_vector(existing_fields, enum_fields, rank \\ "C") do
    existing_fields ++ Enum.map(enum_fields, fn {column, int_ext_tuples} ->
      full_case = Enum.map(int_ext_tuples, fn {int, ext} ->
        "when new.#{column}='#{int}' then '#{ext}'"
      end) |> Enum.join(" ")
      "setweight(to_tsvector('english_nostop', (case #{full_case} else '' end)), '#{rank}')"
    end)
  end

  # for enums, special-casing listing status type to rank use of the internal representation higher
  # (so searching on "FS" or "NEW" will rank for-sale or new listing statuses higher in search results)
  defp assemble_higher_ranked_enum_search_vector(existing_fields, enum_fields) do
    assemble_enum_search_vector(existing_fields, enum_fields, "A")
  end

  defp assemble_ordinal_search_vector(existing_fields, ord_fields) do
    new_ord_search_vectors = Enum.map(ord_fields, fn {column, abbrev} ->
      "setweight(to_tsvector('english_nostop', (coalesce(new.#{column},0)::text || '#{abbrev}')), 'C')"
    end)
    existing_fields ++ new_ord_search_vectors
  end

  defp assemble_fk_search_vector(existing_fields, fk_fields) do
    existing_fields ++ Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "setweight(to_tsvector('english_nostop', coalesce(#{column}_#{table}_#{varchar_column},'')), 'B')"
    end)
  end

  defp assemble_declarations_for_fk_search_vector(fk_fields) do
    "DECLARE\n" <> Enum.join(Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "#{column}_#{table}_#{varchar_column} VARCHAR(255);"
    end),"\n") <> "\n"
  end

  defp assemble_select_intos_for_fk_search_vector(fk_fields) do
    Enum.join(Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "SELECT #{table}.#{varchar_column} INTO #{column}_#{table}_#{varchar_column} FROM #{table} WHERE id = new.#{column};"
    end), "\n") <> "\n"
  end

  defp assemble_search_vector() do
    []
    |> assemble_fulltext_searchable_fields(@fulltext_searchable_fields)
    |> assemble_fk_search_vector(@foreign_key_searchable_fields)
    |> assemble_boolean_search_vector(@boolean_text_searchable_fields)
    |> assemble_enum_search_vector(@enum_text_searchable_fields)
    |> assemble_higher_ranked_enum_search_vector(@higher_ranked_enum_searchable_fields)
    |> assemble_ordinal_search_vector(@ordinal_number_searchable_fields)
    |> Enum.join(" || ")
    |> String.replace_suffix("", ";")
  end

  defp assemble_insert_update_trigger_fields(fields) do
    fields
    |> Enum.map(fn {column, _} ->
      "#{column}"
    end)
    |> Enum.uniq
    |> Enum.join(", ")
  end

  @first_field_name :erlang.element(1, hd(@fulltext_searchable_fields))
  defp first_field_name, do: @first_field_name

  def search_trigger_function_creation_sql do
    """
      CREATE FUNCTION listing_search_trigger() RETURNS trigger AS $$
      #{assemble_declarations_for_fk_search_vector(@foreign_key_searchable_fields)}
        begin
          #{assemble_select_intos_for_fk_search_vector(@foreign_key_searchable_fields)}
          new.search_vector := #{assemble_search_vector()}
          return new;
        end
      $$ LANGUAGE plpgsql
    """
  end

  def listing_search_update_trigger_creation_sql do
    """
      CREATE TRIGGER listing_search_update
      BEFORE INSERT OR UPDATE OF #{assemble_insert_update_trigger_fields(@all_indexable_fields)}
      ON listings
      FOR EACH ROW EXECUTE PROCEDURE listing_search_trigger();
    """
  end

  def previous_up_statements do
    [
      "DROP TEXT SEARCH CONFIGURATION IF EXISTS public.english_nostop;",
      "DROP TEXT SEARCH DICTIONARY IF EXISTS english_stem_nostop;",
      "CREATE TEXT SEARCH DICTIONARY english_stem_nostop (
        Template = snowball
        , Language = english
      );",
      "CREATE TEXT SEARCH CONFIGURATION public.english_nostop ( COPY = pg_catalog.english );",
      "ALTER TEXT SEARCH CONFIGURATION public.english_nostop
        ALTER MAPPING FOR asciiword, asciihword, hword_asciipart, hword, hword_part, word WITH english_stem_nostop;",
      "DROP TRIGGER IF EXISTS listing_search_update ON listings;",
      "DROP FUNCTION IF EXISTS listing_search_trigger();",
      search_trigger_function_creation_sql(),
      listing_search_update_trigger_creation_sql(),
      "UPDATE listings SET #{first_field_name()} = #{first_field_name()}",
    ]
  end

end

defmodule Mpnetwork.Repo.Migrations.AddDraftToFulltextSearchableFields do
  use Ecto.Migration

  alias Mpnetwork.EnumMaps

  # note that if you add to these later or change the ranks, you'll have to rerun a similar migration
  @fulltext_searchable_fields [
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
    selling_broker_name: "C",
  ]

  @boolean_text_searchable_fields [
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
    high_speed_internet_available: "has_high_speed_internet_available has_high_speed_internet high speed internet",
    modern_kitchen_countertops: "has_modern_kitchen_countertops has_granite_countertops modern kitchen countertops",
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
    eef_geothermal_heating: "has_eef_geothermal_heating is_geothermal has_geothermal geothermal heating",
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
    smoking_ok: "has_smoking_ok smoking ok",
  ]

  @enum_text_searchable_fields [
    class_type: EnumMaps.class_types,
    style_type: EnumMaps.style_types,
    green_cert_type: EnumMaps.green_cert_types,
    listing_status_type: EnumMaps.listing_status_types_for_search,
  ]

  # this is also an enum but will be handled specially
  @higher_ranked_enum_searchable_fields [
    listing_status_type: EnumMaps.listing_status_types_for_priority_search,
  ]

  @foreign_key_searchable_fields [
    user_id: {:users, :name},
    broker_id: {:offices, :name},
    colisting_agent_id: {:users, :name},
  ]

  # room, bedroom, bathroom, fireplace, skylight, garage, family, story
  @ordinal_number_searchable_fields [
    num_rooms: "roo",
    num_bedrooms: "bed",
    num_baths: "bat",
    num_fireplaces: "fir",
    num_skylights: "sky",
    num_garages: "gar",
    num_families: "fam",
    stories: "sto",
  ]

  # fields the updating of which should trigger a search reindex, regardless
  @other_reindex_forcing_fields [
    expires_on: nil # due to expiration state possibly changing
  ]

  @all_indexable_fields (@foreign_key_searchable_fields ++ @fulltext_searchable_fields ++ @boolean_text_searchable_fields ++ @enum_text_searchable_fields ++ @ordinal_number_searchable_fields ++ @other_reindex_forcing_fields)

  defp assemble_fulltext_searchable_fields(existing_fields, text_fields) do
    existing_fields ++ Enum.map(text_fields, fn {column, rank} ->
      "setweight(to_tsvector('english_nostop', coalesce(new.#{column},'')), '#{rank}')"
    end)
  end

  defp assemble_boolean_search_vector(existing_fields, boolean_fields) do
    existing_fields ++ Enum.map(boolean_fields, fn {column, text_if_true} ->
      "setweight(to_tsvector('english_nostop', (case when new.#{column} then '#{text_if_true}' else '' end)), 'B')"
    end)
  end

  defp assemble_enum_search_vector(existing_fields, enum_fields, rank \\ "C") do
    existing_fields ++ Enum.map(enum_fields, fn {column, int_ext_tuples} ->
      full_case = Enum.map(int_ext_tuples, fn {int, ext} ->
        "when new.#{column}='#{int}' then '#{ext}'"
      end) |> Enum.join(" ")
      "setweight(to_tsvector('english_nostop', (case #{full_case} else '' end)), '#{rank}')"
    end)
  end

  # for enums, special-casing listing status type to rank use of the internal representation higher
  # (so searching on "FS" or "NEW" will rank for-sale or new listing statuses higher in search results)
  defp assemble_higher_ranked_enum_search_vector(existing_fields, enum_fields) do
    assemble_enum_search_vector(existing_fields, enum_fields, "A")
  end

  defp assemble_ordinal_search_vector(existing_fields, ord_fields) do
    new_ord_search_vectors = Enum.map(ord_fields, fn {column, abbrev} ->
      "setweight(to_tsvector('english_nostop', (coalesce(new.#{column},0)::text || '#{abbrev}')), 'C')"
    end)
    existing_fields ++ new_ord_search_vectors
  end

  defp assemble_fk_search_vector(existing_fields, fk_fields) do
    existing_fields ++ Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "setweight(to_tsvector('english_nostop', coalesce(#{column}_#{table}_#{varchar_column},'')), 'B')"
    end)
  end

  defp assemble_declarations_for_fk_search_vector(fk_fields) do
    "DECLARE\n" <> Enum.join(Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "#{column}_#{table}_#{varchar_column} VARCHAR(255);"
    end),"\n") <> "\n"
  end

  defp assemble_select_intos_for_fk_search_vector(fk_fields) do
    Enum.join(Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "SELECT #{table}.#{varchar_column} INTO #{column}_#{table}_#{varchar_column} FROM #{table} WHERE id = new.#{column};"
    end), "\n") <> "\n"
  end

  defp assemble_search_vector() do
    []
    |> assemble_fulltext_searchable_fields(@fulltext_searchable_fields)
    |> assemble_fk_search_vector(@foreign_key_searchable_fields)
    |> assemble_boolean_search_vector(@boolean_text_searchable_fields)
    |> assemble_enum_search_vector(@enum_text_searchable_fields)
    |> assemble_higher_ranked_enum_search_vector(@higher_ranked_enum_searchable_fields)
    |> assemble_ordinal_search_vector(@ordinal_number_searchable_fields)
    |> Enum.join(" || ")
    |> String.replace_suffix("", ";")
  end

  defp assemble_insert_update_trigger_fields(fields) do
    fields
    |> Enum.map(fn {column, _} ->
      "#{column}"
    end)
    |> Enum.uniq
    |> Enum.join(", ")
  end

  @first_field_name :erlang.element(1, hd(@fulltext_searchable_fields))
  defp first_field_name, do: @first_field_name

  def search_trigger_function_creation_sql do
    """
      CREATE FUNCTION listing_search_trigger() RETURNS trigger AS $$
      #{assemble_declarations_for_fk_search_vector(@foreign_key_searchable_fields)}
        begin
          #{assemble_select_intos_for_fk_search_vector(@foreign_key_searchable_fields)}
          new.search_vector := #{assemble_search_vector()}
          return new;
        end
      $$ LANGUAGE plpgsql
    """
  end

  def listing_search_update_trigger_creation_sql do
    """
      CREATE TRIGGER listing_search_update
      BEFORE INSERT OR UPDATE OF #{assemble_insert_update_trigger_fields(@all_indexable_fields)}
      ON listings
      FOR EACH ROW EXECUTE PROCEDURE listing_search_trigger();
    """
  end

  def up_statements do
    [
      "DROP TRIGGER IF EXISTS listing_search_update ON listings;",
      "DROP FUNCTION IF EXISTS listing_search_trigger();",
      search_trigger_function_creation_sql(),
      listing_search_update_trigger_creation_sql(),
      "UPDATE listings SET #{first_field_name()} = #{first_field_name()}",
    ]
  end

  def up do
    up_statements()
    |> Enum.each(&execute/1)
  end

  def down do
    # this code needs to be idempotent for this trick to work in every migration that changes the search indexing
    Mpnetwork.PreviousMigrations.RemoveStupidStopWords.previous_up_statements
    |> Enum.each(&execute/1)
    # additional_down_statements()
    # |> Enum.each(&execute/1)
  end

end
