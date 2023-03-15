defmodule Mpnetwork.EmailView do
  use MpnetworkWeb, :view
  def nextphoto(nil), do: {nil, nil}
  def nextphoto([]), do: {nil, nil}
  def nextphoto([head | rest]), do: {head, rest}
  def select_photos_from_attachments_and_put_primary_photo_first(attachments) do
    {photo_attachments, _other_attachments} = Enum.split_with(attachments, &(&1.is_image))
    primary_photo = Enum.find(photo_attachments, List.first(photo_attachments), &(&1.primary))
    photos = if primary_photo do
      {primary_photo, (photo_attachments -- [primary_photo])}
    else
      {nil, []}
    end
    photos
  end
  def for_sale_or_for_rent_string(listing) do
    case {listing.for_sale, listing.for_rent || listing.also_for_rent} do
      {true, false} -> "For Sale"
      {false, true} -> "For Rent"
      {true, true} -> "For Sale/Rent"
      _ -> nil
    end
  end
end
