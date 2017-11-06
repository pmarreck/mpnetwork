defmodule Mpnetwork.Permissions do

  alias Mpnetwork.User
  alias Mpnetwork.Realtor.{Listing, Office}

  def site_admin?(%User{} = user) do
    user.role_id < 2
  end

  def office_admin?(%User{} = user) do
    user.role_id == 2
  end

  def office_admin_or_site_admin?(%User{} = user) do
    office_admin?(user) || site_admin?(user)
  end

  def office_admin_of_office_or_site_admin?(%User{} = user, %Office{} = office) do
    (office_admin?(user) && user.office_id == office.id) || site_admin?(user)
  end

  def owner_or_admin_of_same_office_or_site_admin?(%User{} = user, %Listing{} = resource) do
    oid = resource.user_id
    owner = user.id == oid
    resource_belongs_to_users_office = resource.broker_id == user.office_id
    admin_of_same_office = resource_belongs_to_users_office && office_admin?(user)
    (owner || admin_of_same_office || site_admin?(user))
  end

  def owner_or_admin_of_same_office_or_site_admin?(%User{} = user, %User{} = resource) do
    oid = resource.id
    owner = user.id == oid
    resource_belongs_to_users_office = resource.office_id == user.office_id
    admin_of_same_office = resource_belongs_to_users_office && office_admin?(user)
    (owner || admin_of_same_office || site_admin?(user))
  end

end
