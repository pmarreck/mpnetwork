defmodule Mpnetwork.Listing.PriceHistory do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mpnetwork.Listing.PriceHistory


  schema "listing_price_histories" do
    field :price_usd, :integer
    field :listing_id, :id

    timestamps()
  end

  @doc false
  def changeset(%PriceHistory{} = price_history, attrs) do
    price_history
    |> cast(attrs, [:price_usd])
    |> validate_required([:price_usd])
  end
end
