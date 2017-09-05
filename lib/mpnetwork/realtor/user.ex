defmodule Mpnetwork.User do
  @moduledoc false
  use Ecto.Schema
  use Coherence.Schema

  schema "users" do
    field :username, :string, unique: true
    field :email, :string, unique: true
    field :name, :string
    field :office_phone, :string
    field :cell_phone, :string
    # field :password, :string, virtual: true #set via coherence_schema()
    # field :office_id, :integer, default: 1
    # Had to rename the following association to "broker"
    # after "office" became a boolean. Oops.
    belongs_to :broker, Mpnetwork.Realtor.Office, foreign_key: :office_id
    # field :role_id, :integer, default: 3 # Realtor
    belongs_to :role, Mpnetwork.Realtor.Role, defaults: %{id: 3}
    has_many :listings, Mpnetwork.Realtor.Listing
    has_many :broadcasts, Mpnetwork.Realtor.Broadcast

    coherence_schema() # adds :password_hash

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    params = params
    |> copy_email_to_username_unless_username_exists
    |> default_role_to_realtor
    model
    |> cast(params, [:username, :email, :name, :office_phone, :cell_phone, :office_id, :role_id] ++ coherence_fields())
    |> validate_required([:username, :email])
    |> validate_format(:email, email_regex())
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end

  def changeset(model, params, :password) do
    model
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(params)
  end

  defp copy_email_to_username_unless_username_exists(params) do
    # for now the username will default to the email if not otherwise provided
    # for some reason had weird errors flipping between string/atom keys so here you go
    params = cond do
      (params[:email] && !params[:username])  -> Enum.into(%{username: params[:email]}, params)
      (params["email"] && !params["username"]) -> Enum.into(%{"username" => params["email"]}, params)
      true -> params
    end
    params
  end

  defp default_role_to_realtor(params) do
    params = cond do
      (params[:email] && !params[:role_id]) -> Enum.into(%{role_id: 3}, params)
      (params["email"] && !params["role_id"]) -> Enum.into(%{"role_id" => 3}, params)
      true -> params
    end
    params
  end

  # taken from http://www.regular-expressions.info/email.html
  # Added A-Z to char classes to avoid having to use /i switch
  defp email_regex do
    ~r/\A(?=[A-Za-z0-9@.!#$%&'*+\/=?^_`{|}~-]{6,254}\z)
    (?=[A-Za-z0-9.!#$%&'*+\/=?^_`{|}~-]{1,64}@)
    [A-Za-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+\/=?^_`{|}~-]+)*
    @ (?:(?=[A-Za-z0-9-]{1,63}\.)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+
    (?=[A-Za-z0-9-]{1,63}\z)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\z/x
  end

end
