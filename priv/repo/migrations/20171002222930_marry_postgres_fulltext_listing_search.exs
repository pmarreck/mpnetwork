defmodule Mpnetwork.Repo.MarryPostgresFulltextListingSearch do
  use Ecto.Migration

  # The migration wherein we marry Postgres because the cost of using another fulltext
  # search engine is greater than just using Postgres' built-in (and apparently quite capable)
  # fulltext search.

  # note that if you add to these later or change the ranks, you'll have to rerun a similar migration
  @fulltext_searchable_fields [
    address: "A",
    description: "C",
    remarks: "C",
    association: "C",
    neighborhood: "C",
    schools: "B",
    zoning: "C",
    district: "C",
    construction: "C",
    appearance: "C",
    cross_street: "C",
    owner_name: "C"
  ]

  defp assemble_search_vector(fields) do
    fields
    |> Enum.map(fn {column, rank} ->
      "setweight(to_tsvector('pg_catalog.english', coalesce(new.#{column},'')), '#{rank}')"
    end) |> Enum.join(" || ")
    |> String.replace_suffix("", ";")
  end

  defp assemble_insert_update_trigger_fields(fields) do
    fields
    |> Enum.map(fn {column, _} ->
      "#{column}"
    end) |> Enum.join(", ")
  end

  def change do

    alter table(:listings) do
      add :search_vector, :tsvector
    end

    create_if_not_exists index(:listings, [:search_vector], using: "GIN")

    # trying to make these idempotent so they can run inside a "change" migration...
    # Note that execute/2 requires ecto ~2.2
    execute("""
      CREATE OR REPLACE FUNCTION listing_search_trigger() RETURNS trigger AS $$
        begin
          new.search_vector := #{assemble_search_vector(@fulltext_searchable_fields)}
          return new;
        end
      $$ LANGUAGE plpgsql
    ""","""
      DROP FUNCTION IF EXISTS listing_search_trigger();
    """)

    execute("""
      CREATE TRIGGER listing_search_update
      BEFORE INSERT OR UPDATE OF #{assemble_insert_update_trigger_fields(@fulltext_searchable_fields)}
      ON listings
      FOR EACH ROW EXECUTE PROCEDURE listing_search_trigger();
    ""","""
      DROP TRIGGER IF EXISTS listing_search_update ON listings;
    """)

    # now force-update all existing rows to populate search_vector on those rows
    field = :erlang.element(1, hd(@fulltext_searchable_fields))
    execute("UPDATE listings SET #{field} = #{field}", "")

    ~w[draft
       for_sale
       for_rent
       inserted_at
       updated_at
       next_broker_oh_start_at
       next_broker_oh_end_at
       next_cust_oh_start_at
       next_cust_oh_end_at
       class_type
       listing_status_type
       style_type
       att_type
    ]a |> Enum.each(fn col ->
      create_if_not_exists index(:listings, [col])
    end)

    # previous attempt left in for posterity

    # ~w[address
    #    description
    #    remarks
    #    association
    #    neighborhood
    #    schools
    #    zoning
    #    district
    #    construction
    #    appearance
    #    cross_street
    #    owner_name
    # ] |> Enum.each(fn col ->
    #   create_if_not_exists index(:listings, ["to_tsvector('english',#{col})"], using: "GIN")
    #   # create_if_not_exists index(:listings, ["lower(#{col})"])
    # end)

  end
end
