defmodule Mpnetwork.Realtor.Broadcast do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Realtor.Broadcast


  schema "broadcasts" do
    field :title, :string
    field :body, :string

    belongs_to :user, Mpnetwork.User

    timestamps()
  end

  @doc false
  def changeset(%Broadcast{} = broadcast, attrs) do
    broadcast
    |> cast(attrs, [:user_id, :title, :body])
    |> validate_required([:user_id, :title, :body])
  end
end
