defmodule Mpnetwork.Schema.Cache do
  use Mpnetwork.Ecto.Schema

  schema "cache" do
    field :key, Mpnetwork.Ecto.Term
    field :value, Mpnetwork.Ecto.Term
    field :sha256_hash, :binary
    # field :metadata, :map

    timestamps()
  end

  @doc false
  def changeset(cache, attrs) do
    cache
    |> cast(attrs, [:key, :value, :sha256_hash])
    |> validate_required([:key])
  end
end
