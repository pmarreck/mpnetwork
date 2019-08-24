defmodule Mpnetwork.Repo.Migrations.AddSoftDeleteToListings do
  use Ecto.Migration

  def change do
    execute(
      """
      DO $$
      BEGIN
        PERFORM prepare_table_for_soft_delete('listings');
      END $$
      """,
      """
      DO $$
      BEGIN
        PERFORM reverse_table_soft_delete('listings');
      END $$
      """
    )
  end
end
