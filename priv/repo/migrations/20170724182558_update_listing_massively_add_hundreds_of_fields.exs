defmodule Mpnetwork.Repo.Migrations.UpdateListingMassivelyAddHundredsOfFields do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :next_broker_oh_start_at, :naive_datetime
      add :next_broker_oh_end_at, :naive_datetime
      add :next_cust_oh_start_at, :naive_datetime
      add :next_cust_oh_end_at, :naive_datetime
      add :ext_urls, {:array, :string}
      add :broker_id, references(:offices, on_delete: :nothing)
      # Booleans
      ~w[
        porch
        tennis_ct
        mbr_first_fl
        office
        den
        attic
        finished_basement
        w_w_carpet
        wood_floors
        dock_rights
        beach_rights
        waterfront
        waterview
        bulkhead
        cul_de_sac
        corner
        adult_comm
        gated_comm
        eat_in_kitchen
        sewer
        sep_hw_heater
        equestrian
        energy_eff
        green_certified
        eef_energy_star_stove
        eef_energy_star_refrigerator
        eef_energy_star_dishwasher
        eef_energy_star_washer
        eef_energy_star_dryer
        eef_energy_star_water_heater
        eef_geothermal_water_heater
        eef_solar_water_heater
        eef_tankless_water_heater
        eef_double_pane_windows
        eef_insulated_windows
        eef_tinted_windows
        eef_triple_pane_windows
        eef_energy_star_windows
        eef_storm_doors
        eef_insulated_doors
        eef_energy_star_doors
        eef_foam_insulation
        eef_cellulose_insulation
        eef_blown_insulation
        eef_programmable_thermostat
        eef_low_flow_showers_fixtures
        eef_low_flow_dual_flush_toilet
        eef_gray_water_system
        eef_energy_star_furnace
        eef_geothermal_heating
        eef_energy_star_ac
        eef_energy_star_cac
        eef_geothermal_ac
        eef_solar_ac
        eef_solar_panels
        eef_solar_pool_cover
        eef_windmill
        offers_presentable
        lockbox
        broker_agent_owned
        buyer_exclusions
        also_for_rent
        ing_sprinks
        short_sale
        reo
        owner_financing
      ]a
      |> Enum.each(fn c -> add c, :boolean end)
      # Integers
      ~w[
        original_price_usd
        prior_price_usd
        seller_agency_comp
        buyer_agency_comp
        broker_agency_comp
        listing_broker_comp_rental
        section_num
        block_num
        lot_num
        vill_tax_usd
        star_deduc_usd
        water_frontage_ft
        bulkhead_ft
        num_families
        num_kitchens
        ac_num_zones
        heat_num_zones
        green_cert_year
        rental_income_usd
        num_rooms
        lot_sqft
        building_size_sqft
      ]a
      |> Enum.each(fn c -> add c, :integer end)
      # Varchars
      ~w[
        tennis_ct_desc
        selling_agent_name
        association
        neighborhood
        schools
        zoning
        district
        construction
        appearance
        cross_street
        owner_name
        status_showing_phone
        show_instr
        personal_prop_exclusions
        permit
        occupancy
        basement_desc
        first_fl_desc
        second_fl_desc
        third_fl_desc
        lot_size
        driveway
      ]a
      |> Enum.each(fn c -> add c, :string end)
      # Text blobs
      ~w[
        next_broker_oh_note
        next_cust_oh_note
        directions
      ]a
      |> Enum.each(fn c -> add c, :text end)

    end

  end

end
