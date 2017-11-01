Code.require_file("20171002222930_marry_postgres_fulltext_listing_search.exs", "priv/repo/migrations/")
defmodule Mpnetwork.Repo.Migrations.ReviseFulltextListingSearch do

  use Ecto.Migration

  alias Mpnetwork.EnumMaps

  # The migration wherein we marry Postgres because the cost of using another fulltext
  # search engine is greater than just using Postgres' built-in (and apparently quite capable)
  # fulltext search.

  # note that if you add to these later or change the ranks, you'll have to rerun a similar migration
  @fulltext_searchable_fields [
    address: "A",
    city: "B",
    state: "B",
    zip: "B",
    description: "C",
    directions: "D",
    remarks: "C",
    association: "C",
    neighborhood: "C",
    schools: "B",
    zoning: "C",
    district: "C",
    construction: "C",
    appearance: "C",
    basement_desc: "C",
    first_fl_desc: "C",
    second_fl_desc: "C",
    third_fl_desc: "C",
    cross_street: "C",
    owner_name: "C",
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
    listing_status_type: EnumMaps.listing_status_types_for_search,
  ]

  # this is also an enum but will be handled specially
  @higher_ranked_enum_searchable_fields [
    listing_status_type: EnumMaps.listing_status_types_for_priority_search,
  ]

  @foreign_key_searchable_fields [
    user_id: {:users, :name},
    broker_id: {:offices, :name}
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

  @all_indexable_fields (@foreign_key_searchable_fields ++ @fulltext_searchable_fields ++ @boolean_text_searchable_fields ++ @enum_text_searchable_fields ++ @ordinal_number_searchable_fields)

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

  # adds "expired" as an indexed word on any listing with listing_status_type of CL or with expired_on date in the past
  # note that this is not an automatically-acquired search attribute; the listing has to be updated to reflect this
  defp assemble_expired_search_vector(existing_fields) do
    existing_fields ++ ["setweight(to_tsvector('english', (case when new.listing_status_type='CL' then 'expired' when new.expires_on < (clock_timestamp() at time zone 'utc')::date then 'expired' else '' end)), 'A')"]
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
    existing_fields ++ Enum.map(fk_fields, fn {_column, {table, varchar_column}} ->
      "setweight(to_tsvector('english', coalesce(#{table}_#{varchar_column},'')), 'B')"
    end)
  end

  defp assemble_declarations_for_fk_search_vector(fk_fields) do
    "DECLARE\n" <> Enum.join(Enum.map(fk_fields, fn {_column, {table, varchar_column}} ->
      "#{table}_#{varchar_column} VARCHAR(255);"
    end),"\n") <> "\n"
  end

  defp assemble_select_intos_for_fk_search_vector(fk_fields) do
    Enum.join(Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "SELECT #{table}.#{varchar_column} INTO #{table}_#{varchar_column} FROM #{table} WHERE id = new.#{column};"
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
    |> assemble_expired_search_vector()
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

  def up do
    execute("DROP TRIGGER IF EXISTS listing_search_update ON listings;")
    execute("DROP FUNCTION IF EXISTS listing_search_trigger();")
    execute(search_trigger_function_creation_sql())
    execute(listing_search_update_trigger_creation_sql())
    execute("UPDATE listings SET #{first_field_name()} = #{first_field_name()}")
    # IO.puts "OLD SEARCH TRIGGER FUNCTION:"
    # IO.puts Mpnetwork.Repo.MarryPostgresFulltextListingSearch.search_trigger_function_creation_sql()
    # IO.puts "NEW SEARCH TRIGGER FUNCTION:"
    # IO.puts search_trigger_function_creation_sql()
    # IO.puts "OLD UPDATE TRIGGER:"
    # IO.puts Mpnetwork.Repo.MarryPostgresFulltextListingSearch.listing_search_update_trigger_creation_sql()
    # IO.puts "NEW UPDATE TRIGGER:"
    # IO.puts listing_search_update_trigger_creation_sql()
  end

  def down do
    execute("DROP TRIGGER IF EXISTS listing_search_update ON listings;")
    execute("DROP FUNCTION IF EXISTS listing_search_trigger();")
    execute(Mpnetwork.Repo.MarryPostgresFulltextListingSearch.search_trigger_function_creation_sql())
    execute(Mpnetwork.Repo.MarryPostgresFulltextListingSearch.listing_search_update_trigger_creation_sql())
    execute("UPDATE listings SET #{first_field_name()} = #{first_field_name()}")
  end

end
