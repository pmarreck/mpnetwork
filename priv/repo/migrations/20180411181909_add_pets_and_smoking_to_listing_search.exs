# References to earlier migration files fail in production
# due to files being in different places or not even available.
# So this is the SQL statement construction code from the previous listing-search migration,
# copied more or less verbatim, and namespaced differently,
# to be used in the "down" of THIS migration.

# See the module def below this one for the actual migration.

defmodule Mpnetwork.PreviousMigrations.ModifyListingSearchForExpiredListings1 do
  # use Ecto.Migration # comment this out or running the migration will complain about no up or change function

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
      "setweight(to_tsvector('english', coalesce(new.#{column},'')), '#{rank}')"
    end)
  end

  defp assemble_boolean_search_vector(existing_fields, boolean_fields) do
    existing_fields ++ Enum.map(boolean_fields, fn {column, text_if_true} ->
      "setweight(to_tsvector('english', (case when new.#{column} then '#{text_if_true}' else '' end)), 'C')"
    end)
  end

  defp assemble_enum_search_vector(existing_fields, enum_fields, rank \\ "C") do
    existing_fields ++ Enum.map(enum_fields, fn {column, int_ext_tuples} ->
      full_case = Enum.map(int_ext_tuples, fn {int, ext} ->
        "when new.#{column}='#{int}' then '#{ext}'"
      end) |> Enum.join(" ")
      "setweight(to_tsvector('english', (case #{full_case} else '' end)), '#{rank}')"
    end)
  end

  # for enums, special-casing listing status type to rank use of the internal representation higher
  # (so searching on "FS" or "NEW" will rank for-sale or new listing statuses higher in search results)
  defp assemble_higher_ranked_enum_search_vector(existing_fields, enum_fields) do
    assemble_enum_search_vector(existing_fields, enum_fields, "A")
  end

  defp assemble_ordinal_search_vector(existing_fields, ord_fields) do
    new_ord_search_vectors = Enum.map(ord_fields, fn {column, abbrev} ->
      "setweight(to_tsvector('english', (coalesce(new.#{column},0)::text || '#{abbrev}')), 'C')"
    end)
    existing_fields ++ new_ord_search_vectors
  end

  defp assemble_fk_search_vector(existing_fields, fk_fields) do
    existing_fields ++ Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "setweight(to_tsvector('english', coalesce(#{column}_#{table}_#{varchar_column},'')), 'B')"
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

end

########## ACTUAL START OF THIS FILE'S MIGRATION CODE ##########
defmodule Mpnetwork.Repo.Migrations.AddPetsAndSmokingToListingSearch do
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
      "setweight(to_tsvector('english', coalesce(new.#{column},'')), '#{rank}')"
    end)
  end

  defp assemble_boolean_search_vector(existing_fields, boolean_fields) do
    existing_fields ++ Enum.map(boolean_fields, fn {column, text_if_true} ->
      "setweight(to_tsvector('english', (case when new.#{column} then '#{text_if_true}' else '' end)), 'C')"
    end)
  end

  defp assemble_enum_search_vector(existing_fields, enum_fields, rank \\ "C") do
    existing_fields ++ Enum.map(enum_fields, fn {column, int_ext_tuples} ->
      full_case = Enum.map(int_ext_tuples, fn {int, ext} ->
        "when new.#{column}='#{int}' then '#{ext}'"
      end) |> Enum.join(" ")
      "setweight(to_tsvector('english', (case #{full_case} else '' end)), '#{rank}')"
    end)
  end

  # for enums, special-casing listing status type to rank use of the internal representation higher
  # (so searching on "FS" or "NEW" will rank for-sale or new listing statuses higher in search results)
  defp assemble_higher_ranked_enum_search_vector(existing_fields, enum_fields) do
    assemble_enum_search_vector(existing_fields, enum_fields, "A")
  end

  defp assemble_ordinal_search_vector(existing_fields, ord_fields) do
    new_ord_search_vectors = Enum.map(ord_fields, fn {column, abbrev} ->
      "setweight(to_tsvector('english', (coalesce(new.#{column},0)::text || '#{abbrev}')), 'C')"
    end)
    existing_fields ++ new_ord_search_vectors
  end

  defp assemble_fk_search_vector(existing_fields, fk_fields) do
    existing_fields ++ Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "setweight(to_tsvector('english', coalesce(#{column}_#{table}_#{varchar_column},'')), 'B')"
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
    Mpnetwork.PreviousMigrations.ModifyListingSearchForExpiredListings1.up_statements()
    |> Enum.each(&execute/1)
  end

end
