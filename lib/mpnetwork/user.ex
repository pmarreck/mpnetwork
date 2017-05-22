defmodule Mpnetwork.User do
  use Ecto.Schema

  schema "users" do
    field :username, :string, unique: true
    field :email, :string, unique: true
    field :fullname, :string
    field :firstname, :string
    field :lastname, :string
    field :office_phone, :string
    field :cell_phone, :string
    field :encrypted_password, :string
    field :office_id, :integer
    field :role_id, :integer


    timestamps()
  end
end
