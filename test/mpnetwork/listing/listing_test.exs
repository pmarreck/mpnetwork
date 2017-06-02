defmodule Mpnetwork.ListingTest do
  use Mpnetwork.DataCase

  alias Mpnetwork.Listing

  describe "attachments" do
    alias Mpnetwork.Listing.Attachment

    @valid_attrs %{content_type: "some content_type", data: "some data", height_pixels: 42, original_filename: "some original_filename", primary: true, sha256_hash: "some sha256_hash", width_pixels: 42}
    @update_attrs %{content_type: "some updated content_type", data: "some updated data", height_pixels: 43, original_filename: "some updated original_filename", primary: false, sha256_hash: "some updated sha256_hash", width_pixels: 43}
    @invalid_attrs %{content_type: nil, data: nil, height_pixels: nil, original_filename: nil, primary: nil, sha256_hash: nil, width_pixels: nil}

    def attachment_fixture(attrs \\ %{}) do
      {:ok, attachment} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Listing.create_attachment()

      attachment
    end

    test "list_attachments/0 returns all attachments" do
      attachment = attachment_fixture()
      assert Listing.list_attachments() == [attachment]
    end

    test "get_attachment!/1 returns the attachment with given id" do
      attachment = attachment_fixture()
      assert Listing.get_attachment!(attachment.id) == attachment
    end

    test "create_attachment/1 with valid data creates a attachment" do
      assert {:ok, %Attachment{} = attachment} = Listing.create_attachment(@valid_attrs)
      assert attachment.content_type == "some content_type"
      assert attachment.data == "some data"
      assert attachment.height_pixels == 42
      assert attachment.original_filename == "some original_filename"
      assert attachment.primary == true
      assert attachment.sha256_hash == "some sha256_hash"
      assert attachment.width_pixels == 42
    end

    test "create_attachment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Listing.create_attachment(@invalid_attrs)
    end

    test "update_attachment/2 with valid data updates the attachment" do
      attachment = attachment_fixture()
      assert {:ok, attachment} = Listing.update_attachment(attachment, @update_attrs)
      assert %Attachment{} = attachment
      assert attachment.content_type == "some updated content_type"
      assert attachment.data == "some updated data"
      assert attachment.height_pixels == 43
      assert attachment.original_filename == "some updated original_filename"
      assert attachment.primary == false
      assert attachment.sha256_hash == "some updated sha256_hash"
      assert attachment.width_pixels == 43
    end

    test "update_attachment/2 with invalid data returns error changeset" do
      attachment = attachment_fixture()
      assert {:error, %Ecto.Changeset{}} = Listing.update_attachment(attachment, @invalid_attrs)
      assert attachment == Listing.get_attachment!(attachment.id)
    end

    test "delete_attachment/1 deletes the attachment" do
      attachment = attachment_fixture()
      assert {:ok, %Attachment{}} = Listing.delete_attachment(attachment)
      assert_raise Ecto.NoResultsError, fn -> Listing.get_attachment!(attachment.id) end
    end

    test "change_attachment/1 returns a attachment changeset" do
      attachment = attachment_fixture()
      assert %Ecto.Changeset{} = Listing.change_attachment(attachment)
    end
  end
end
