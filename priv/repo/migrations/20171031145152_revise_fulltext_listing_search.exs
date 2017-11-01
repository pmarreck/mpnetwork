# Code.require_file("20171002222930_marry_postgres_fulltext_listing_search.exs", "priv/repo/migrations/")
# The above line is required to make some of the below commented-out code work IN DEV, but fails in production
# due to files being in different places or not even available.
# Left as a reference for how to revise a huge function/trigger with idempotent rollback/"down".
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

  # def puts_and_return(s), do: IO.puts(s) && s

  def up do
    execute("DROP TRIGGER IF EXISTS listing_search_update ON listings;")
    execute("DROP FUNCTION IF EXISTS listing_search_trigger();")
    execute(search_trigger_function_creation_sql())
    execute(listing_search_update_trigger_creation_sql())
    # IO.puts "OLD SEARCH TRIGGER FUNCTION:"
    # IO.puts Mpnetwork.Repo.MarryPostgresFulltextListingSearch.search_trigger_function_creation_sql()
    # IO.puts "NEW SEARCH TRIGGER FUNCTION:"
    # IO.puts search_trigger_function_creation_sql()
    # IO.puts "OLD UPDATE TRIGGER:"
    # IO.puts Mpnetwork.Repo.MarryPostgresFulltextListingSearch.listing_search_update_trigger_creation_sql()
    # IO.puts "NEW UPDATE TRIGGER:"
    # IO.puts listing_search_update_trigger_creation_sql()
    execute("UPDATE listings SET #{first_field_name()} = #{first_field_name()}")
  end

  def down do
    execute("DROP TRIGGER IF EXISTS listing_search_update ON listings;")
    execute("DROP FUNCTION IF EXISTS listing_search_trigger();")
    execute("""
      CREATE OR REPLACE FUNCTION listing_search_trigger() RETURNS trigger AS $$
      DECLARE
      users_name VARCHAR(255);
      offices_name VARCHAR(255);

        begin
          SELECT users.name INTO users_name FROM users WHERE id = new.user_id;
      SELECT offices.name INTO offices_name FROM offices WHERE id = new.broker_id;

          new.search_vector := setweight(to_tsvector('english', coalesce(new.address,'')), 'A') || setweight(to_tsvector('english', coalesce(new.city,'')), 'B') || setweight(to_tsvector('english', coalesce(new.state,'')), 'B') || setweight(to_tsvector('english', coalesce(new.zip,'')), 'B') || setweight(to_tsvector('english', coalesce(new.description,'')), 'C') || setweight(to_tsvector('english', coalesce(new.remarks,'')), 'C') || setweight(to_tsvector('english', coalesce(new.association,'')), 'C') || setweight(to_tsvector('english', coalesce(new.neighborhood,'')), 'C') || setweight(to_tsvector('english', coalesce(new.schools,'')), 'B') || setweight(to_tsvector('english', coalesce(new.zoning,'')), 'C') || setweight(to_tsvector('english', coalesce(new.district,'')), 'C') || setweight(to_tsvector('english', coalesce(new.construction,'')), 'C') || setweight(to_tsvector('english', coalesce(new.appearance,'')), 'C') || setweight(to_tsvector('english', coalesce(new.cross_street,'')), 'C') || setweight(to_tsvector('english', coalesce(new.owner_name,'')), 'C') || setweight(to_tsvector('english', coalesce(users_name,'')), 'B') || setweight(to_tsvector('english', coalesce(offices_name,'')), 'B') || setweight(to_tsvector('english', (case when new.studio then 'studio' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.for_sale then 'for sale' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.for_rent then 'for rent' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.basement then 'basement' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.attached_garage then 'attached garage' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.new_construction then 'new construction' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.patio then 'patio' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.deck then 'deck' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.pool then 'pool' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.hot_tub then 'hot tub' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.porch then 'porch' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.central_air then 'central air' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.central_vac then 'central vac' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.security_system then 'security system' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.fios_available then 'FIOS' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.high_speed_internet_available then 'high speed internet' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.modern_kitchen_countertops then 'modern kitchen countertops' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.eef_led_lighting then 'LED lighting' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.tennis_ct then 'tennis court' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.mbr_first_fl then 'master bedroom first floor' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.office then 'office' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.den then 'den' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.attic then 'attic' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.finished_basement then 'finished basement' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.w_w_carpet then 'wall to wall carpet' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.wood_floors then 'wood floors' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.dock_rights then 'dock rights' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.beach_rights then 'beach rights' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.waterfront then 'waterfront' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.waterview then 'waterview' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.bulkhead then 'bulkhead' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.cul_de_sac then 'cul de sac' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.corner then 'corner' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.adult_comm then 'adult community' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.gated_comm then 'gated community' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.eat_in_kitchen then 'eat-in kitchen' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.energy_eff then 'energy efficient' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.green_certified then 'green certified' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.eef_geothermal_heating then 'geothermal heating' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.eef_solar_panels then 'solar' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.eef_windmill then 'windmill' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.ing_sprinks then 'inground sprinklers' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.short_sale then 'short sale' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.reo then 'REO' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.handicap_access then 'handicapped handicap' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.equestrian then 'horse' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.also_for_rent then 'for rent' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.buyer_exclusions then 'buyer exclusions' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.broker_agent_owned then 'broker/agent broker agent owned' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.class_type='residential' then 'Residential' when new.class_type='condo' then 'Condo' when new.class_type='co_op' then 'Co-op' when new.class_type='hoa' then 'HOA' when new.class_type='rental' then 'Rental' when new.class_type='land' then 'Land' when new.class_type='commercial_industrial' then 'Commercial/Industrial' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.listing_status_type='NEW' then 'New' when new.listing_status_type='FS' then 'For Sale' when new.listing_status_type='EXT' then 'Extended' when new.listing_status_type='UC' then 'Under Contract' when new.listing_status_type='CL' then 'Closed Sold' when new.listing_status_type='PC' then 'Price Change' when new.listing_status_type='WR' then 'Withdrawn' when new.listing_status_type='TOM' then 'Temporarily Off Market' else '' end)), 'C') || setweight(to_tsvector('english', (case when new.style_type='2_story' then '2 Story' when new.style_type='antique_hist' then 'Antique/Hist' when new.style_type='barn' then 'Barn' when new.style_type='bungalow' then 'Bungalow' when new.style_type='cape' then 'Cape' when new.style_type='colonial' then 'Colonial' when new.style_type='contemporary' then 'Contemporary' when new.style_type='cottage' then 'Cottage' when new.style_type='duplex' then 'Duplex' when new.style_type='estate' then 'Estate' when new.style_type='exp_cape' then 'Exp Cape' when new.style_type='exp_ranch' then 'Exp Ranch' when new.style_type='farm_ranch' then 'Farm Ranch' when new.style_type='farmhouse' then 'Farmhouse' when new.style_type='hi_ranch' then 'Hi Ranch' when new.style_type='houseboat' then 'Houseboat' when new.style_type='mediterranean' then 'Mediterranean' when new.style_type='mobile_home' then 'Mobile Home' when new.style_type='modern' then 'Modern' when new.style_type='nantucket' then 'Nantucket' when new.style_type='postmodern' then 'Postmodern' when new.style_type='prewar' then 'Prewar' when new.style_type='raised_ranch' then 'Raised Ranch' when new.style_type='ranch' then 'Ranch' when new.style_type='saltbox' then 'Saltbox' when new.style_type='splanch' then 'Splanch' when new.style_type='split' then 'Split' when new.style_type='split_ranch' then 'Split Ranch' when new.style_type='store_dwell' then 'Store+Dwell' when new.style_type='townhouse' then 'Townhouse' when new.style_type='traditional' then 'Traditional' when new.style_type='tudor' then 'Tudor' when new.style_type='victorian' then 'Victorian' when new.style_type='other' then 'Other' else '' end)), 'C');
          return new;
        end
      $$ LANGUAGE plpgsql
    """)
    execute("""
      CREATE TRIGGER listing_search_update
      BEFORE INSERT OR UPDATE OF user_id, broker_id, address, city, state, zip, description, remarks, association, neighborhood, schools, zoning, district, construction, appearance, cross_street, owner_name, studio, for_sale, for_rent, basement, attached_garage, new_construction, patio, deck, pool, hot_tub, porch, central_air, central_vac, security_system, fios_available, high_speed_internet_available, modern_kitchen_countertops, eef_led_lighting, tennis_ct, mbr_first_fl, office, den, attic, finished_basement, w_w_carpet, wood_floors, dock_rights, beach_rights, waterfront, waterview, bulkhead, cul_de_sac, corner, adult_comm, gated_comm, eat_in_kitchen, energy_eff, green_certified, eef_geothermal_heating, eef_solar_panels, eef_windmill, ing_sprinks, short_sale, reo, handicap_access, equestrian, also_for_rent, buyer_exclusions, broker_agent_owned, class_type, listing_status_type, style_type
      ON listings
      FOR EACH ROW EXECUTE PROCEDURE listing_search_trigger();
    """)
    execute("UPDATE listings SET #{first_field_name()} = #{first_field_name()}")
  end

end
