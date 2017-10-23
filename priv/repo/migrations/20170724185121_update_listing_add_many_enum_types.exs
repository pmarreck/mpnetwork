defmodule Mpnetwork.Repo.Migrations.UpdateListingAddManyEnumTypes do
  use Ecto.Migration

  defp idempotency do
    ~w[
      class_type
      listing_status_type
      basement_type
      waterfront_type
      compass_point_type
      style_type
      dining_room_type
      fuel_type
      heating_type
      sewage_type
      water_type
      sep_hw_heater_type
      green_cert_type
      patio_type
      porch_type
      pool_type
      deck_type
      att_type
    ]
    |> Enum.each(fn t -> execute("DROP TYPE IF EXISTS #{t} CASCADE;") end)
  end

  def up do
    idempotency()

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
    AttachmentTypeEnum.create_type

    alter table(:listings) do
      add :class_type, :class_type
      add :listing_status_type, :listing_status_type
      add :basement_type, :basement_type
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
      add :pool_type, :pool_type
      add :deck_type, :deck_type
      add :att_type, :att_type
    end

  end

  def down do

    alter table(:listings) do
      remove :class_type
      remove :listing_status_type
      remove :basement_type
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
      remove :pool_type
      remove :deck_type
      remove :att_type
    end

    idempotency()
    # ClassTypeEnum.drop_type
    # ListingStatusTypeEnum.drop_type
    # BasementTypeEnum.drop_type
    # WaterfrontTypeEnum.drop_type
    # CompassPointEnum.drop_type
    # StyleTypeEnum.drop_type
    # DiningRoomTypeEnum.drop_type
    # FuelTypeEnum.drop_type
    # HeatingTypeEnum.drop_type
    # SewageTypeEnum.drop_type
    # WaterTypeEnum.drop_type
    # SepHwHeaterTypeEnum.drop_type
    # GreenCertTypeEnum.drop_type
    # PatioTypeEnum.drop_type
    # PorchTypeEnum.drop_type
    # PoolTypeEnum.drop_type
    # DeckTypeEnum.drop_type
    # AttachmentTypeEnum.drop_type
  end

end
