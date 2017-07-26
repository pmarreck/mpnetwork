defmodule Mpnetwork.Repo.Migrations.UpdateListingAddManyEnumTypes do
  use Ecto.Migration

  def up do

    ClassTypeEnum.create_type
    ListingStatusTypeEnum.create_type
    BasementTypeEnum.create_type
    WaterfrontTypeEnum.create_type
    CompassPointEnum.create_type
    StyleTypeEnum.create_type
    DiningRoomTypeEnum.create_type
    FuelTypeEnum.create_type
    HeatingTypeEnum.create_type
    SewageTypeEnum.create_type
    WaterTypeEnum.create_type
    SepHwHeaterTypeEnum.create_type
    GreenCertTypeEnum.create_type
    PatioTypeEnum.create_type
    PorchTypeEnum.create_type
    PoolTypeEnum.create_type
    DeckTypeEnum.create_type

    alter table(:listings) do
      add :class_type, :class_type
      add :listing_status_type, :listing_status_type
      add :basement_type, :basement_type
      remove :new_appliances
      remove :ext_url
      add :waterfront_type, :waterfront_type
      add :front_exposure_type, :compass_point_type
      add :style_type, :style_type
      add :dining_room_type, :dining_room_type
      add :fuel_type, :fuel_type
      add :heating_type, :heating_type
      add :sewage_type, :sewage_type
      add :water_type, :water_type
      add :sep_hw_heater_type, :sep_hw_heater_type
      add :green_cert_type, :green_cert_type
      add :patio_type, :patio_type
      add :porch_type, :porch_type
      remove :lot_size_acre_cents
      add :pool_type, :pool_type
      add :deck_type, :deck_type
    end

  end

  def down do

    alter table(:listings) do
      remove :class_type
      remove :listing_status_type
      remove :basement_type
      add :new_appliances, :boolean
      add :ext_url, :string
      remove :waterfront_type
      remove :front_exposure_type
      remove :style_type
      remove :dining_room_type
      remove :fuel_type
      remove :heating_type
      remove :sewage_type
      remove :water_type
      remove :sep_hw_heater_type
      remove :green_cert_type
      remove :patio_type
      remove :porch_type
      add :lot_size_acre_cents, :integer
      remove :pool_type
      remove :deck_type
    end

    ClassTypeEnum.drop_type
    ListingStatusTypeEnum.drop_type
    BasementTypeEnum.drop_type
    WaterfrontTypeEnum.drop_type
    CompassPointEnum.drop_type
    StyleTypeEnum.drop_type
    DiningRoomTypeEnum.drop_type
    FuelTypeEnum.drop_type
    HeatingTypeEnum.drop_type
    SewageTypeEnum.drop_type
    WaterTypeEnum.drop_type
    SepHwHeaterTypeEnum.drop_type
    GreenCertTypeEnum.drop_type
    PatioTypeEnum.drop_type
    PorchTypeEnum.drop_type
    PoolTypeEnum.drop_type
    DeckTypeEnum.drop_type
  end

end
