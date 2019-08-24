defmodule Mpnetwork.Realtor.Broadcast do
  use Mpnetwork.Ecto.Schema
  alias Mpnetwork.Realtor.Broadcast

  schema "broadcasts" do
    field(:title, :string)
    field(:body, :string)

    belongs_to(:user, Mpnetwork.User)

    timestamps()
  end

  @doc false
  def changeset(%Broadcast{} = broadcast, attrs) do
    broadcast
    |> cast(attrs, [:user_id, :title, :body])
    |> validate_required([:user_id, :title, :body])
    |> validate_length(:title, max: 255, count: :codepoints)
    |> validate_length(:body, max: 4096, count: :codepoints)
    |> foreign_key_constraint(:user_id)
  end
end
