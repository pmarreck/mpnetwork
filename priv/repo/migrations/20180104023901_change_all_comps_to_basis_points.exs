defmodule Mpnetwork.Repo.Migrations.ChangeAllCompsToBasisPoints do
  use Ecto.Migration

  def up do
    execute "UPDATE listings SET seller_agency_comp = seller_agency_comp * 100"
    execute "UPDATE listings SET buyer_agency_comp = buyer_agency_comp * 100"
    execute "UPDATE listings SET broker_agency_comp = broker_agency_comp * 100"
  end

  def down do
    execute "UPDATE listings SET seller_agency_comp = seller_agency_comp / 100"
    execute "UPDATE listings SET buyer_agency_comp = buyer_agency_comp / 100"
    execute "UPDATE listings SET broker_agency_comp = broker_agency_comp / 100"
  end
end
