defmodule Mpnetwork.EnumMaps do

  # Housing Class Types
  @class_types_ext ~w[Residential Condo Co-op HOA Rental Land Commercial/Industrial]
  @class_types_int (@class_types_ext |> Enum.map(&(String.downcase(&1) |> String.replace(~r/[^a-z0-9]/, "_") |> String.to_atom)))
  def class_types_int, do: @class_types_int
  @class_type_opts Enum.zip([" " | @class_types_ext], [nil | @class_types_int])
  def class_type_select_opts, do: @class_type_opts

  @class_types_int_to_ext_map Enum.zip(@class_types_int, @class_types_ext) |> Map.new
  @class_types_ext_to_int_map Enum.zip(@class_types_ext, @class_types_int) |> Map.new

  def map_class_type_int_to_ext(k) when is_atom(k), do: @class_types_int_to_ext_map[k]
  def map_class_type_int_to_ext(k) when is_binary(k), do: map_class_type_int_to_ext(String.to_existing_atom(k))
  def map_class_type_ext_to_int(k) when is_binary(k), do: @class_types_ext_to_int_map[k]

  # Listing Status Types
  @listing_status_types_ext ["New", "For Sale", "Extended", "Under Contract", "Closed (Sold)", "Price Change", "Withdrawn", "Temporarily Off Market"]
  @listing_status_types_int ~w[NEW FS EXT UC CL PC WR TOM]a
  @listing_status_types_int_bin Enum.map(@listing_status_types_int, fn atom -> Atom.to_string(atom) end)
  def listing_status_types_int, do: @listing_status_types_int
  def listing_status_types_int_bin, do: @listing_status_types_int_bin

  @listing_status_type_opts Enum.zip([" " | @listing_status_types_ext], [nil | @listing_status_types_int])
  def listing_status_type_select_opts, do: @listing_status_type_opts
  # perhaps instead attribute "New" if listing is under a month old?

  @listing_status_types_int_to_ext_map Enum.zip(@listing_status_types_int, @listing_status_types_ext) |> Map.new
  @listing_status_types_ext_to_int_map Enum.zip(@listing_status_types_ext, @listing_status_types_int) |> Map.new

  def map_listing_status_type_int_to_ext(k) when is_atom(k), do: @listing_status_types_int_to_ext_map[k]
  def map_listing_status_type_int_to_ext(k) when is_binary(k), do: map_listing_status_type_int_to_ext(String.to_existing_atom(k))
  def map_listing_status_type_ext_to_int(k) when is_binary(k), do: @listing_status_types_ext_to_int_map[k]

  # Basement Types
  @basement_types_ext ~w[Full Part Crawl Opt None]
  @basement_types_int ~w[full part crawl opt none]a
  def basement_types_int, do: @basement_types_int
  @basement_type_opts Enum.zip([" " | @basement_types_ext], [nil | @basement_types_int])
  def basement_type_select_opts, do: @basement_type_opts

  @basement_types_int_to_ext_map Enum.zip(@basement_types_int, @basement_types_ext) |> Map.new
  @basement_types_ext_to_int_map Enum.zip(@basement_types_ext, @basement_types_int) |> Map.new

  def map_basement_type_int_to_ext(k) when is_atom(k), do: @basement_types_int_to_ext_map[k]
  def map_basement_type_int_to_ext(k) when is_binary(k), do: map_basement_type_int_to_ext(String.to_existing_atom(k))
  def map_basement_type_ext_to_int(k) when is_binary(k), do: @basement_types_ext_to_int_map[k]

  # Waterfront Types
  @waterfront_types_ext ["Bay", "Canal", "Creek", "Harbor", "Inlet", "Lake", "Ocean", "Pond", "Prot Wetland", "River", "Sound", "Other"]
  @waterfront_types_int ~w[bay canal creek harbor inlet lake ocean pond wetland river sound other]a
  def waterfront_types_int, do: @waterfront_types_int
  @waterfront_type_opts Enum.zip([" " | @waterfront_types_ext], [nil | @waterfront_types_int])
  def waterfront_type_select_opts, do: @waterfront_type_opts

  @waterfront_types_int_to_ext_map Enum.zip(@waterfront_types_int, @waterfront_types_ext) |> Map.new
  @waterfront_types_ext_to_int_map Enum.zip(@waterfront_types_ext, @waterfront_types_int) |> Map.new

  def map_waterfront_type_int_to_ext(k) when is_atom(k), do: @waterfront_types_int_to_ext_map[k]
  def map_waterfront_type_int_to_ext(k) when is_binary(k), do: map_waterfront_type_int_to_ext(String.to_existing_atom(k))
  def map_waterfront_type_ext_to_int(k) when is_binary(k), do: @waterfront_types_ext_to_int_map[k]

  # Front Exposure Types
  @front_exposure_types_ext ~w[N S E W NE NW SE SW]
  @front_exposure_types_int ~w[N S E W NE NW SE SW]a
  def front_exposure_types_int, do: @front_exposure_types_int
  @front_exposure_type_opts Enum.zip([" " | @front_exposure_types_ext], [nil | @front_exposure_types_int])
  def front_exposure_type_select_opts, do: @front_exposure_type_opts

  @front_exposure_types_int_to_ext_map Enum.zip(@front_exposure_types_int, @front_exposure_types_ext) |> Map.new
  @front_exposure_types_ext_to_int_map Enum.zip(@front_exposure_types_ext, @front_exposure_types_int) |> Map.new

  def map_front_exposure_type_int_to_ext(k) when is_atom(k), do: @front_exposure_types_int_to_ext_map[k]
  def map_front_exposure_type_int_to_ext(k) when is_binary(k), do: map_front_exposure_type_int_to_ext(String.to_existing_atom(k))
  def map_front_exposure_type_ext_to_int(k) when is_binary(k), do: @front_exposure_types_ext_to_int_map[k]

  # Housing Style Types
  @style_types_ext ["2 Story", "Antique/Hist", "Barn", "Bungalow", "Cape", "Colonial", "Contemporary", "Cottage", "Duplex", "Estate", "Exp Cape", "Exp Ranch",
                    "Farm Ranch", "Farmhouse", "Hi Ranch", "Houseboat", "Mediterranean", "Mobile Home", "Modern", "Nantucket", "Postmodern", "Prewar", "Raised Ranch",
                    "Ranch", "Saltbox", "Splanch", "Split", "Split Ranch", "Store+Dwell", "Townhouse", "Traditional", "Tudor", "Victorian", "Other"]
  @style_types_int (@style_types_ext |> Enum.map(&(String.downcase(&1) |> String.replace(~r/[^a-z0-9]/, "_") |> String.to_atom)))
  def style_types_int, do: @style_types_int
  @style_type_opts Enum.zip([" " | @style_types_ext], [nil | @style_types_int])
  def style_type_select_opts, do: @style_type_opts

  @style_types_int_to_ext_map Enum.zip(@style_types_int, @style_types_ext) |> Map.new
  @style_types_ext_to_int_map Enum.zip(@style_types_ext, @style_types_int) |> Map.new

  def map_style_type_int_to_ext(k) when is_atom(k), do: @style_types_int_to_ext_map[k]
  def map_style_type_int_to_ext(k) when is_binary(k), do: map_style_type_int_to_ext(String.to_existing_atom(k))
  def map_style_type_ext_to_int(k) when is_binary(k), do: @style_types_ext_to_int_map[k]

  # Dining Room Types
  @dining_room_types_ext ["Formal", "L-Shaped", "Lr/Dr", "None", "Other"]
  @dining_room_types_int (@dining_room_types_ext |> Enum.map(&(String.downcase(&1) |> String.replace(~r/[^a-z0-9]/, "_") |> String.to_atom)))
  def dining_room_types_int, do: @dining_room_types_int
  @dining_room_type_opts Enum.zip([" " | @dining_room_types_ext], [nil | @dining_room_types_int])
  def dining_room_type_select_opts, do: @dining_room_type_opts

  @dining_room_types_int_to_ext_map Enum.zip(@dining_room_types_int, @dining_room_types_ext) |> Map.new
  @dining_room_types_ext_to_int_map Enum.zip(@dining_room_types_ext, @dining_room_types_int) |> Map.new

  def map_dining_room_type_int_to_ext(k) when is_atom(k), do: @dining_room_types_int_to_ext_map[k]
  def map_dining_room_type_int_to_ext(k) when is_binary(k), do: map_dining_room_type_int_to_ext(String.to_existing_atom(k))
  def map_dining_room_type_ext_to_int(k) when is_binary(k), do: @dining_room_types_ext_to_int_map[k]

  # Fuel Types
  @fuel_types_ext ["Elec", "Gas", "Oil", "Solar", "Other"]
  @fuel_types_int ~w[elec gas oil solar other]a
  def fuel_types_int, do: @fuel_types_int
  @fuel_type_opts Enum.zip([" " | @fuel_types_ext], [nil | @fuel_types_int])
  def fuel_type_select_opts, do: @fuel_type_opts

  @fuel_types_int_to_ext_map Enum.zip(@fuel_types_int, @fuel_types_ext) |> Map.new
  @fuel_types_ext_to_int_map Enum.zip(@fuel_types_ext, @fuel_types_int) |> Map.new

  def map_fuel_type_int_to_ext(k) when is_atom(k), do: @fuel_types_int_to_ext_map[k]
  def map_fuel_type_int_to_ext(k) when is_binary(k), do: map_fuel_type_int_to_ext(String.to_existing_atom(k))
  def map_fuel_type_ext_to_int(k) when is_binary(k), do: @fuel_types_ext_to_int_map[k]

  # Heating Types
  @heating_types_ext ["None", "Elec", "Heat Pump/CAC", "HA/Furnace", "HW/Boiler", "GeoX", "Rad", "Steam", "Other"]
  @heating_types_int (@heating_types_ext |> Enum.map(&(String.downcase(&1) |> String.replace(~r/[^a-z0-9]/, "_") |> String.to_atom)))
  def heating_types_int, do: @heating_types_int
  @heating_type_opts Enum.zip([" " | @heating_types_ext], [nil | @heating_types_int])
  def heating_type_select_opts, do: @heating_type_opts

  @heating_types_int_to_ext_map Enum.zip(@heating_types_int, @heating_types_ext) |> Map.new
  @heating_types_ext_to_int_map Enum.zip(@heating_types_ext, @heating_types_int) |> Map.new

  def map_heating_type_int_to_ext(k) when is_atom(k), do: @heating_types_int_to_ext_map[k]
  def map_heating_type_int_to_ext(k) when is_binary(k), do: map_heating_type_int_to_ext(String.to_existing_atom(k))
  def map_heating_type_ext_to_int(k) when is_binary(k), do: @heating_types_ext_to_int_map[k]

  # Sewage Types
  @sewage_types_ext ["Municipal Sewer", "Cesspool", "Septic"]
  @sewage_types_int ~w[sewer cesspool septic]a
  def sewage_types_int, do: @sewage_types_int
  @sewage_type_opts Enum.zip([" " | @sewage_types_ext], [nil | @sewage_types_int])
  def sewage_type_select_opts, do: @sewage_type_opts

  @sewage_types_int_to_ext_map Enum.zip(@sewage_types_int, @sewage_types_ext) |> Map.new
  @sewage_types_ext_to_int_map Enum.zip(@sewage_types_ext, @sewage_types_int) |> Map.new

  def map_sewage_type_int_to_ext(k) when is_atom(k), do: @sewage_types_int_to_ext_map[k]
  def map_sewage_type_int_to_ext(k) when is_binary(k), do: map_sewage_type_int_to_ext(String.to_existing_atom(k))
  def map_sewage_type_ext_to_int(k) when is_binary(k), do: @sewage_types_ext_to_int_map[k]

  # Water Types
  @water_types_ext ~w[Public Well]
  @water_types_int ~w[public well]a
  def water_types_int, do: @water_types_int
  @water_type_opts Enum.zip([" " | @water_types_ext], [nil | @water_types_int])
  def water_type_select_opts, do: @water_type_opts

  @water_types_int_to_ext_map Enum.zip(@water_types_int, @water_types_ext) |> Map.new
  @water_types_ext_to_int_map Enum.zip(@water_types_ext, @water_types_int) |> Map.new

  def map_water_type_int_to_ext(k) when is_atom(k), do: @water_types_int_to_ext_map[k]
  def map_water_type_int_to_ext(k) when is_binary(k), do: map_water_type_int_to_ext(String.to_existing_atom(k))
  def map_water_type_ext_to_int(k) when is_binary(k), do: @water_types_ext_to_int_map[k]

  # Separate Hot Water Heater Types
  @sep_hw_heater_types_ext ["Elec", "Gas", "Oil", "Solar", "Other"]
  @sep_hw_heater_types_int ~w[elec gas oil solar other]a
  def sep_hw_heater_types_int, do: @sep_hw_heater_types_int
  @sep_hw_heater_type_opts Enum.zip([" " | @sep_hw_heater_types_ext], [nil | @sep_hw_heater_types_int])
  def sep_hw_heater_type_select_opts, do: @sep_hw_heater_type_opts

  @sep_hw_heater_types_int_to_ext_map Enum.zip(@sep_hw_heater_types_int, @sep_hw_heater_types_ext) |> Map.new
  @sep_hw_heater_types_ext_to_int_map Enum.zip(@sep_hw_heater_types_ext, @sep_hw_heater_types_int) |> Map.new

  def map_sep_hw_heater_type_int_to_ext(k) when is_atom(k), do: @sep_hw_heater_types_int_to_ext_map[k]
  def map_sep_hw_heater_type_int_to_ext(k) when is_binary(k), do: map_sep_hw_heater_type_int_to_ext(String.to_existing_atom(k))
  def map_sep_hw_heater_type_ext_to_int(k) when is_binary(k), do: @sep_hw_heater_types_ext_to_int_map[k]

  # Green Certification Types
  @green_cert_types_ext ["Energy Star", "HERS", "LEED", "LEED Gold", "LEED Silver", "LEED Platinum"]
  @green_cert_types_int (@green_cert_types_ext |> Enum.map(&(String.downcase(&1) |> String.replace(~r/[^a-z0-9]/, "_") |> String.to_atom)))
  def green_cert_types_int, do: @green_cert_types_int
  @green_cert_type_opts Enum.zip([" " | @green_cert_types_ext], [nil | @green_cert_types_int])
  def green_cert_type_select_opts, do: @green_cert_type_opts

  @green_cert_types_int_to_ext_map Enum.zip(@green_cert_types_int, @green_cert_types_ext) |> Map.new
  @green_cert_types_ext_to_int_map Enum.zip(@green_cert_types_ext, @green_cert_types_int) |> Map.new

  def map_green_cert_type_int_to_ext(k) when is_atom(k), do: @green_cert_types_int_to_ext_map[k]
  def map_green_cert_type_int_to_ext(k) when is_binary(k), do: map_green_cert_type_int_to_ext(String.to_existing_atom(k))
  def map_green_cert_type_ext_to_int(k) when is_binary(k), do: @green_cert_types_ext_to_int_map[k]

  # Patio Types
  @patio_types_int ~w[brick bluestone concrete ceramic_tile porcelain_tile limestone pavers quartzite slate wood other]a
  @patio_types_ext (@patio_types_int |> Enum.map(&(Atom.to_string(&1) |> String.replace(~r/_/, " ") |> String.capitalize)))
  def patio_types_int, do: @patio_types_int
  @patio_type_opts Enum.zip([" " | @patio_types_ext], [nil | @patio_types_int])
  def patio_type_select_opts, do: @patio_type_opts

  @patio_types_int_to_ext_map Enum.zip(@patio_types_int, @patio_types_ext) |> Map.new
  @patio_types_ext_to_int_map Enum.zip(@patio_types_ext, @patio_types_int) |> Map.new

  def map_patio_type_int_to_ext(k) when is_atom(k), do: @patio_types_int_to_ext_map[k]
  def map_patio_type_int_to_ext(k) when is_binary(k), do: map_patio_type_int_to_ext(String.to_existing_atom(k))
  def map_patio_type_ext_to_int(k) when is_binary(k), do: @patio_types_ext_to_int_map[k]

  # Porch Types (same as patio types for now)
  @porch_types_int @patio_types_int
  # @porch_types_ext @patio_types_ext # unused so far
  def porch_types_int, do: @porch_types_int
  @porch_type_opts @patio_type_opts
  def porch_type_select_opts, do: @porch_type_opts

  @porch_types_int_to_ext_map @patio_types_int_to_ext_map
  @porch_types_ext_to_int_map @patio_types_ext_to_int_map

  def map_porch_type_int_to_ext(k) when is_atom(k), do: @porch_types_int_to_ext_map[k]
  def map_porch_type_int_to_ext(k) when is_binary(k), do: map_porch_type_int_to_ext(String.to_existing_atom(k))
  def map_porch_type_ext_to_int(k) when is_binary(k), do: @porch_types_ext_to_int_map[k]

  # Pool Types
  @pool_types_ext ["Above-ground", "Fiberglass", "Concrete", "Vinyl", "Gunite", "Shotcrete", "Masonry block", "Lap", "Freeform", "Other"]
  @pool_types_int (@pool_types_ext |> Enum.map(&(String.downcase(&1) |> String.replace(~r/[^a-z0-9]/, "_") |> String.to_atom)))
  def pool_types_int, do: @pool_types_int
  @pool_type_opts Enum.zip([" " | @pool_types_ext], [nil | @pool_types_int])
  def pool_type_select_opts, do: @pool_type_opts

  @pool_types_int_to_ext_map Enum.zip(@pool_types_int, @pool_types_ext) |> Map.new
  @pool_types_ext_to_int_map Enum.zip(@pool_types_ext, @pool_types_int) |> Map.new

  def map_pool_type_int_to_ext(k) when is_atom(k), do: @pool_types_int_to_ext_map[k]
  def map_pool_type_int_to_ext(k) when is_binary(k), do: map_pool_type_int_to_ext(String.to_existing_atom(k))
  def map_pool_type_ext_to_int(k) when is_binary(k), do: @pool_types_ext_to_int_map[k]

  # Deck Types
  @deck_types_ext ["Hardwood", "PT Lumber", "Redwood", "Cedar", "Tropical hardwood", "Composite", "Plastic", "Aluminum", "Other"]
  @deck_types_int (@deck_types_ext |> Enum.map(&(String.downcase(&1) |> String.replace(~r/[^a-z0-9]/, "_") |> String.to_atom)))
  def deck_types_int, do: @deck_types_int
  @deck_type_opts Enum.zip([" " | @deck_types_ext], [nil | @deck_types_int])
  def deck_type_select_opts, do: @deck_type_opts

  @deck_types_int_to_ext_map Enum.zip(@deck_types_int, @deck_types_ext) |> Map.new
  @deck_types_ext_to_int_map Enum.zip(@deck_types_ext, @deck_types_int) |> Map.new

  def map_deck_type_int_to_ext(k) when is_atom(k), do: @deck_types_int_to_ext_map[k]
  def map_deck_type_int_to_ext(k) when is_binary(k), do: map_deck_type_int_to_ext(String.to_existing_atom(k))
  def map_deck_type_ext_to_int(k) when is_binary(k), do: @deck_types_ext_to_int_map[k]

  # Attachment Types
  @att_types_ext ["Single-family detached", "Attached", "Semi"]
  @att_types_int ~w[ det att semi ]a
  def att_types_int, do: @att_types_int
  @att_type_opts Enum.zip([" " | @att_types_ext], [nil | @att_types_int])
  def att_type_select_opts, do: @att_type_opts

  @att_types_int_to_ext_map Enum.zip(@att_types_int, @att_types_ext) |> Map.new
  @att_types_ext_to_int_map Enum.zip(@att_types_ext, @att_types_int) |> Map.new

  def map_att_type_int_to_ext(k) when is_atom(k), do: @att_types_int_to_ext_map[k]
  def map_att_type_int_to_ext(k) when is_binary(k), do: map_att_type_int_to_ext(String.to_existing_atom(k))
  def map_att_type_ext_to_int(k) when is_binary(k), do: @att_types_ext_to_int_map[k]

  # List of Energy-Efficient Features (note: NOT a type. Just seemed appropriate to keep here.)
  @eef_features_ext [
    "Energy Star Stove",
    "Energy Star Refrigerator",
    "Energy Star Dishwasher",
    "Energy Star Washer",
    "Energy Star Dryer",
    "Energy Star Water Heater",
    "Geothermal Water Heater",
    "Solar Water Heater",
    "Tankless Water Heater",
    "Double Pane Windows",
    "Insulated Windows",
    "Tinted Windows",
    "Triple Pane Windows",
    "Energy Star Windows",
    "Storm Doors",
    "Insulated Doors",
    "Energy Star Doors",
    "Foam Insulation",
    "Cellulose Insulation",
    "Blown Insulation",
    "Programmable Thermostat",
    "Low Flow Showers/Fixtures",
    "Low Flow/Dual Flush Toilet",
    "Gray Water System",
    "Energy Star Furnace",
    "Geothermal Heating",
    "Energy Star A/C",
    "Energy Star CAC",
    "Geothermal A/C",
    "Solar A/C",
    "Solar Panels",
    "Solar Pool Cover",
    "Windmill",
  ]
  @eef_features_int ~w[
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
  ]a
  def eef_features_int, do: @eef_features_int
  @eef_features_int_to_ext_map Enum.zip(@eef_features_int, @eef_features_ext) |> Map.new
  @eef_features_ext_to_int_map Enum.zip(@eef_features_ext, @eef_features_int) |> Map.new

  def map_eef_feature_int_to_ext(k) when is_atom(k), do: @eef_features_int_to_ext_map[k]
  def map_eef_feature_int_to_ext(k) when is_binary(k), do: map_eef_feature_int_to_ext(String.to_existing_atom(k))
  def map_eef_feature_ext_to_int(k) when is_binary(k), do: @eef_features_ext_to_int_map[k]

end

import EctoEnum, only: :macros
alias Mpnetwork.EnumMaps, as: Enums
defenum ClassTypeEnum, :class_type, Enums.class_types_int()
defenum ListingStatusTypeEnum, :listing_status_type, Enums.listing_status_types_int()
defenum BasementTypeEnum, :basement_type, Enums.basement_types_int()
defenum WaterfrontTypeEnum, :waterfront_type, Enums.waterfront_types_int()
defenum CompassPointEnum, :compass_point_type, Enums.front_exposure_types_int()
defenum StyleTypeEnum, :style_type, Enums.style_types_int()
defenum DiningRoomTypeEnum, :dining_room_type, Enums.dining_room_types_int()
defenum FuelTypeEnum, :fuel_type, Enums.fuel_types_int()
defenum HeatingTypeEnum, :heating_type, Enums.heating_types_int()
defenum SewageTypeEnum, :sewage_type, Enums.sewage_types_int()
defenum WaterTypeEnum, :water_type, Enums.water_types_int()
defenum SepHwHeaterTypeEnum, :sep_hw_heater_type, Enums.sep_hw_heater_types_int()
defenum GreenCertTypeEnum, :green_cert_type, Enums.green_cert_types_int()
defenum PatioTypeEnum, :patio_type, Enums.patio_types_int()
defenum PorchTypeEnum, :porch_type, Enums.porch_types_int()
defenum PoolTypeEnum, :pool_type, Enums.pool_types_int()
defenum DeckTypeEnum, :deck_type, Enums.deck_types_int()
defenum AttachmentTypeEnum, :att_type, Enums.att_types_int()
