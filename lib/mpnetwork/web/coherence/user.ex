defmodule Mpnetwork.User do
  @moduledoc false
  use Ecto.Schema
  use Coherence.Schema

  schema "users" do
    field :username, :string, unique: true
    field :email, :string, unique: true
    field :fullname, :string
    field :firstname, :string
    field :lastname, :string
    field :office_phone, :string
    field :cell_phone, :string
    # field :password, :string, virtual: true #set via coherence_schema()
    field :office_id, :integer
    field :role_id, :integer

    coherence_schema() # adds :password_hash

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:username, :email, :fullname, :office_phone, :cell_phone, :office_id, :role_id ] ++ coherence_fields())
    |> validate_required([:username, :email, :office_id])
    |> validate_format(:email, email_regex())
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end

  def changeset(model, params, :password) do
    model
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(params)
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
