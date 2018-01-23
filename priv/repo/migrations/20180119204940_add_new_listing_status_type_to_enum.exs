defmodule Mpnetwork.Repo.Migrations.AddNewListingStatusTypeToEnum do
  use Ecto.Migration
  @disable_ddl_transaction true # altering types cannot be done in a transaction

  alias Mpnetwork.EnumMaps

  defp singly_quoted_list(list) when is_list(list) do
    list
    |> Enum.map(fn i -> "'#{i}'" end)
    |> Enum.join(", ")
  end

  # oh god, I have to drop and recreate the entire goddamn search index function
  # in order to modify an enum type it depends on
  # so I basically have to rebuild the whole damn thing every time
  # Maybe using enum types was not such a great idea :/

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

  defp assemble_insert_update_trigger_fields(fields) do
    fields
    |> Enum.map(fn {column, _} ->
      "#{column}"
    end)
    |> Enum.uniq
    |> Enum.join(", ")
  end

  def listing_search_update_trigger_creation_sql do
    """
      CREATE TRIGGER listing_search_update
      BEFORE INSERT OR UPDATE OF #{assemble_insert_update_trigger_fields(@all_indexable_fields)}
      ON listings
      FOR EACH ROW EXECUTE PROCEDURE listing_search_trigger();
    """
  end

  # Add one or more enum values.
  def add_enum_values_and_modify_column(enum_type_name, enum_type_values, table_name, column_name)
    when is_list(enum_type_values) and is_binary(enum_type_name) and is_binary(table_name) and is_binary(column_name) do
    [
      "DROP TRIGGER IF EXISTS listing_search_update ON listings;",
      "DROP TYPE IF EXISTS #{enum_type_name}_temp;",
      "CREATE TYPE #{enum_type_name}_temp AS ENUM (#{singly_quoted_list(enum_type_values)});",
      "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} TYPE #{enum_type_name}_temp USING (#{column_name}::text::#{enum_type_name}_temp);",
      "DROP TYPE #{enum_type_name};",
      "ALTER TYPE #{enum_type_name}_temp RENAME TO #{enum_type_name};",
      listing_search_update_trigger_creation_sql(),
    ]
  end

  # Drop a single enum value at a time, citing what value to convert any row using that value to.
  def drop_enum_value_and_modify_column(enum_type_name, enum_type_values, enum_type_deleted_value, value_to_change_removed_values_to, table_name, column_name)
    when is_list(enum_type_values) and is_binary(enum_type_name) and is_binary(enum_type_deleted_value) and is_binary(table_name) and is_binary(column_name) do
    [
      "DROP TRIGGER IF EXISTS listing_search_update ON listings;",
      "DROP TYPE IF EXISTS #{enum_type_name}_temp;",
      "CREATE TYPE #{enum_type_name}_temp AS ENUM (#{singly_quoted_list(enum_type_values)});",
      "UPDATE #{table_name} SET #{column_name} = #{if value_to_change_removed_values_to, do: "'"<>value_to_change_removed_values_to<>"'", else: "NULL"} WHERE #{column_name} = '#{enum_type_deleted_value}';",
      "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} TYPE #{enum_type_name}_temp USING (#{column_name}::text::#{enum_type_name}_temp);",
      "DROP TYPE #{enum_type_name};",
      "ALTER TYPE #{enum_type_name}_temp RENAME TO #{enum_type_name};",
      listing_search_update_trigger_creation_sql(),
    ]
  end

  def up do
    add_enum_values_and_modify_column("listing_status_type", EnumMaps.listing_status_types_int, "listings", "listing_status_type")
    |> Enum.each(&execute/1)
    # Technically we should probably also be updating the search index/trigger/stored proc,
    # but it already handles adding an indexable "expired" keyword if the expiration date is in the past...
    # Of course, I just realized it only does that if the listing is updated...
    # Which is the daily-expiration-checker job I'm about to write.
  end



  def down do
    # OK so to do this properly we'd need to
    # 1) UPDATE any values using the about-to-be-removed value to something else (NULL?)
    # 2) convert the column to varchar
    # 3) drop the old type
    # 4) recreate the new type without the new value
    # 5) convert the varchar column back to that new type
    # We are not going to do this proper because that is too much work
    # and this is a down migration that will almost never (if ever) be run.
    # If this was an up migration, I'd do it proper. So...
    # We're going to update any existing rows that use the about-to-be-removed value to NULL
    # and then directly modify the pg_enum table to remove the value.

    # EDIT: We have to do this properly after all because the deploy fails due to
    # lack of access to modifying pg_enum table on a hosted instance. LOL :/

    drop_enum_value_and_modify_column("listing_status_type", ~w[NEW FS EXT UC CL PC WR TOM], "EXP", nil, "listings", "listing_status_type")
    |> Enum.each(&execute/1)

  end

end
