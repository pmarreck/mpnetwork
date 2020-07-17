defmodule Mpnetwork.Repo.Migrations.CreateMpnetwork.Realtor.Listing do
  use Ecto.Migration

  def change do
    create table(:listings) do
      add :draft, :boolean, default: false, null: false
      add :for_sale, :boolean, default: false, null: false
      add :for_rent, :boolean, default: false, null: false
      add :description, :text
      add :address, :string
      add :city, :string
      add :state, :string
      add :zip, :string
      add :price_usd, :integer
      add :studio, :boolean, default: false, null: false
      add :num_bedrooms, :integer
      add :num_baths, :integer
      add :num_half_baths, :integer
      add :sq_ft, :integer
      add :year_built, :integer
      add :stories, :integer
      add :basement, :boolean, default: false, null: false
      add :num_fireplaces, :integer
      add :parking_spaces, :integer
      add :mls_source_id, :integer
      add :num_garages, :integer
      add :attached_garage, :boolean, default: false, null: false
      add :new_construction, :boolean, default: false, null: false
      add :tax_rate_code_area, :integer
      add :prop_tax_usd, :integer
      add :patio, :boolean, default: false, null: false
      add :deck, :boolean, default: false, null: false
      add :pool, :boolean, default: false, null: false
      add :hot_tub, :boolean, default: false, null: false
      add :num_skylights, :integer
      add :handicap_access, :boolean
      add :handicap_access_desc, :string
      add :central_air, :boolean, default: false, null: false
      add :central_vac, :boolean, default: false, null: false
      add :security_system, :boolean, default: false, null: false
      add :fios_available, :boolean, default: false, null: false
      add :high_speed_internet_available, :boolean, default: false, null: false
      add :modern_kitchen_countertops, :boolean, default: false, null: false
      add :cellular_coverage_quality, :integer
      add :eef_led_lighting, :boolean, default: false, null: false
      add :remarks, :text
      add :visible_on, :date
      add :expires_on, :date
      add :user_id, :bigint
      add :siding_desc, :string

      timestamps()
    end

    alter table(:listings) do
      modify :user_id, references(:users, on_delete: :delete_all), from: :integer
    end

    create index(:listings, [:user_id])
  end
end
