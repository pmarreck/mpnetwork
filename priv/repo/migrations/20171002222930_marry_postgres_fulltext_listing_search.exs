defmodule Mpnetwork.Repo.MarryPostgresFulltextListingSearch do
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
    remarks: "C",
    association: "C",
    neighborhood: "C",
    schools: "B",
    zoning: "C",
    district: "C",
    construction: "C",
    appearance: "C",
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
    broker_agent_owned: "broker/agent broker agent owned"
  ]

  @enum_text_searchable_fields [
    class_type: EnumMaps.class_types,
    listing_status_type: EnumMaps.listing_status_types_for_search,
    style_type: EnumMaps.style_types
  ]

  @foreign_key_searchable_fields [
    user_id: {:users, :name},
    broker_id: {:offices, :name}
  ]

  defp assemble_boolean_search_vector(existing_fields, boolean_fields) do
    existing_fields ++ Enum.map(boolean_fields, fn {column, text_if_true} ->
      "setweight(to_tsvector('pg_catalog.english', (case when new.#{column} then '#{text_if_true}' else '' end)), 'C')"
    end)
  end

  defp assemble_enum_search_vector(existing_fields, enum_fields) do
    new_enum_search_vectors = Enum.map(enum_fields, fn {column, int_ext_tuples} ->
      full_case = Enum.map(int_ext_tuples, fn {int, ext} ->
        "when new.#{column}='#{int}' then '#{ext}'"
      end) |> Enum.join(" ")
      "setweight(to_tsvector('pg_catalog.english', (case #{full_case} else '' end)), 'C')"
    end)
    existing_fields ++ new_enum_search_vectors
  end

  defp assemble_fk_search_vector(existing_fields, fk_fields) do
    existing_fields ++ Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "setweight(to_tsvector('pg_catalog.english', coalesce(#{table}_#{varchar_column},'')), 'B')"
    end)
  end

  defp assemble_declarations_for_fk_search_vector(fk_fields) do
    "DECLARE\n" <> Enum.join(Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "#{table}_#{varchar_column} VARCHAR(255);"
    end),"\n") <> "\n"
  end

  defp assemble_select_intos_for_fk_search_vector(fk_fields) do
    Enum.join(Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "SELECT #{table}.#{varchar_column} INTO #{table}_#{varchar_column} FROM #{table} WHERE id = new.#{column};"
    end), "\n") <> "\n"
  end

  defp assemble_search_vector() do
    @fulltext_searchable_fields
    |> (Enum.map(fn {column, rank} ->
      "setweight(to_tsvector('pg_catalog.english', coalesce(new.#{column},'')), '#{rank}')"
    end)
    |> assemble_fk_search_vector(@foreign_key_searchable_fields)
    |> assemble_boolean_search_vector(@boolean_text_searchable_fields)
    |> assemble_enum_search_vector(@enum_text_searchable_fields))
    |> Enum.join(" || ")
    |> String.replace_suffix("", ";")
  end

  defp assemble_insert_update_trigger_fields(fields) do
    fields
    |> Enum.map(fn {column, _} ->
      "#{column}"
    end) |> Enum.join(", ")
  end

  def change do

    alter table(:listings) do
      add :search_vector, :tsvector
    end

    create_if_not_exists index(:listings, [:search_vector], using: "GIN")

    # trying to make these idempotent so they can run inside a "change" migration...
    # Note that execute/2 requires ecto ~2.2
    execute("""
      CREATE OR REPLACE FUNCTION listing_search_trigger() RETURNS trigger AS $$
      #{assemble_declarations_for_fk_search_vector(@foreign_key_searchable_fields)}
        begin
          #{assemble_select_intos_for_fk_search_vector(@foreign_key_searchable_fields)}
          new.search_vector := #{assemble_search_vector()}
          return new;
        end
      $$ LANGUAGE plpgsql
    ""","""
      DROP FUNCTION IF EXISTS listing_search_trigger();
    """)

    execute("""
      CREATE TRIGGER listing_search_update
      BEFORE INSERT OR UPDATE OF #{assemble_insert_update_trigger_fields(@foreign_key_searchable_fields ++ @fulltext_searchable_fields ++ @boolean_text_searchable_fields ++ @enum_text_searchable_fields)}
      ON listings
      FOR EACH ROW EXECUTE PROCEDURE listing_search_trigger();
    ""","""
      DROP TRIGGER IF EXISTS listing_search_update ON listings;
    """)

    # now force-update all existing rows to populate search_vector on those rows
    field = :erlang.element(1, hd(@fulltext_searchable_fields))
    execute("UPDATE listings SET #{field} = #{field}", "")

    ~w[draft
       for_sale
       for_rent
       inserted_at
       updated_at
       next_broker_oh_start_at
       next_broker_oh_end_at
       next_cust_oh_start_at
       next_cust_oh_end_at
       class_type
       listing_status_type
       style_type
       att_type
       price_usd
    ]a |> Enum.each(fn col ->
      create_if_not_exists index(:listings, [col])
    end)

    # previous attempt left in for posterity

    # ~w[address
    #    description
    #    remarks
    #    association
    #    neighborhood
    #    schools
    #    zoning
    #    district
    #    construction
    #    appearance
    #    cross_street
    #    owner_name
    # ] |> Enum.each(fn col ->
    #   create_if_not_exists index(:listings, ["to_tsvector('english',#{col})"], using: "GIN")
    #   # create_if_not_exists index(:listings, ["lower(#{col})"])
    # end)

  end
end
