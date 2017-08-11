defmodule Mpnetwork.Repo.Migrations.AddAttachmentTypeEnumToListing do
  use Ecto.Migration

  def up do
    AttachmentTypeEnum.create_type
    alter table(:listings) do
      add :att_type, :att_type
    end
  end

  def down do
    alter table(:listings) do
      remove :att_type
    end
    AttachmentTypeEnum.drop_type
  end
end
