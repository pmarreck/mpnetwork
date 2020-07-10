defmodule Mpnetwork.Ecto.MigrationSupport do
  @moduledoc """
  Support for trigger and stored proc teardown/rebuild for migrations which affect fields on listings, or search,
  and for other migration support such as soft-delete functionality
  """

  def i(thing) do
    IO.inspect(thing, limit: 100_000, printable_limit: 100_000, pretty: true)
  end

  def singly_quoted_list(list) when is_list(list) do
    list
    |> Enum.map(fn i -> "'#{i}'" end)
    |> Enum.join(", ")
  end

  def assemble_fulltext_searchable_fields(text_fields) do
    Enum.map(text_fields, fn {column, rank} ->
      "setweight(to_tsvector('english_nostop', coalesce(new.#{column},'')), '#{rank}')"
    end)
  end

  def assemble_boolean_search_vector(boolean_fields) do
    Enum.map(boolean_fields, fn {column, text_if_true} ->
      "setweight(to_tsvector('english_nostop', (case when new.#{column} then '#{
        text_if_true
      }' else '' end)), 'B')"
    end)
  end

  def assemble_enum_search_vector(enum_fields, rank \\ "C") do
    Enum.map(enum_fields, fn {column, int_ext_tuples} ->
      full_case =
        Enum.map(int_ext_tuples, fn {int, ext} ->
          "when new.#{column}='#{int}' then '#{ext}'"
        end)
        |> Enum.join(" ")
      "setweight(to_tsvector('english_nostop', (case #{full_case} else '' end)), '#{rank}')"
    end)
  end

  # for enums, special-casing listing status type to rank use of the internal representation higher
  # (so searching on "FS" or "NEW" will rank for-sale or new listing statuses higher in search results)
  def assemble_higher_ranked_enum_search_vector(enum_fields) do
    assemble_enum_search_vector(enum_fields, "A")
  end

  def assemble_ordinal_search_vector(ord_fields) do
    Enum.map(ord_fields, fn {column, abbrev} ->
      "setweight(to_tsvector('english_nostop', (coalesce(new.#{column},0)::text || '#{
        abbrev
      }')), 'C')"
    end)
  end

  def assemble_fk_search_vector(fk_fields) do
    Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
      "setweight(to_tsvector('english_nostop', coalesce(#{column}_#{table}_#{varchar_column},'')), 'B')"
    end)
  end

  def assemble_declarations_for_fk_search_vector(fk_fields) do
    "DECLARE\n" <>
      Enum.join(
        Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
          "#{column}_#{table}_#{varchar_column} VARCHAR(255);"
        end),
        "\n"
      ) <> "\n"
  end

  def assemble_select_intos_for_fk_search_vector(fk_fields) do
    Enum.join(
      Enum.map(fk_fields, fn {column, {table, varchar_column}} ->
        "SELECT #{table}.#{varchar_column} INTO #{column}_#{table}_#{varchar_column} FROM #{
          table
        } WHERE id = new.#{column};"
      end),
      "\n"
    ) <> "\n"
  end

  def assemble_search_vector(schema_state) when is_map(schema_state) do
    [
      assemble_fulltext_searchable_fields(schema_state.fulltext_searchable_fields),
      assemble_fk_search_vector(schema_state.foreign_key_searchable_fields),
      assemble_boolean_search_vector(schema_state.boolean_text_searchable_fields),
      assemble_enum_search_vector(schema_state.enum_text_searchable_fields),
      assemble_higher_ranked_enum_search_vector(schema_state.higher_ranked_enum_searchable_fields),
      assemble_ordinal_search_vector(schema_state.ordinal_number_searchable_fields)
    ]
    |> List.flatten
    |> Enum.join(" || ")
    |> String.replace_suffix("", "; ")
  end

  def assemble_insert_update_trigger_fields(fields) do
    fields
    |> Enum.map(fn {column, _} ->
      "#{column}"
    end)
    |> Enum.uniq()
    |> Enum.join(", ")
  end

  def first_field_name(schema_state), do: :erlang.element(1, hd(schema_state.fulltext_searchable_fields))

  def search_trigger_function_creation_sql(schema_state) when is_map(schema_state) do
    ["""
      CREATE OR REPLACE FUNCTION listing_search_trigger() RETURNS trigger AS $$
      #{assemble_declarations_for_fk_search_vector(schema_state.foreign_key_searchable_fields)}
        begin
          #{assemble_select_intos_for_fk_search_vector(schema_state.foreign_key_searchable_fields)}
          new.search_vector := #{assemble_search_vector(schema_state)}
          return new;
        end
      $$ LANGUAGE plpgsql
    """]
  end

  def listing_search_update_trigger_creation_sql(schema_state) when is_map(schema_state) do
    ["""
      CREATE TRIGGER listing_search_update
      BEFORE INSERT OR UPDATE OF #{
        assemble_insert_update_trigger_fields(schema_state.all_indexable_fields)
      }
      ON listings
      FOR EACH ROW EXECUTE PROCEDURE listing_search_trigger();
    """]
  end

  # NOTE THAT UNDOING SOFTDELETE, EVEN TEMPORARILY, ALSO REMOVES THE deleted_at COLUMN!
  # Consider rewriting the softdelete undo sproc to leave deleted_at alone
  # and the softdelete creation sproc to not add the column if it exists already
  def undo_softdelete_sql(table) do
    ["""
    DO $$
    BEGIN
      PERFORM reverse_table_soft_delete('#{table}');
    END $$
    """]
  end

  def undo_softdelete_view_sql(table) do
    ["DROP VIEW without_softdeleted.#{table};"]
  end

  def undo_search_index_function_sql() do
    ["DROP FUNCTION IF EXISTS listing_search_trigger()"]
  end

  def undo_search_index_trigger_sql() do
    ["DROP TRIGGER IF EXISTS listing_search_update ON listings"]
  end

  def redo_softdelete_sql(table) do
    ["""
      DO $$
      BEGIN
        PERFORM prepare_table_for_soft_delete('#{table}');
      END $$
    """]
  end

  def redo_softdelete_view_sql(table) do
    ["""
      CREATE VIEW without_softdeleted.#{table} AS SELECT * FROM #{table} WHERE deleted_at IS NULL;
    """]
  end

  def redo_search_index_trigger_sql(schema_state) when is_map(schema_state) do
    # for idempotency
    [
      undo_search_index_trigger_sql(),
      listing_search_update_trigger_creation_sql(schema_state)
    ]
  end

  # Add one or more enum values.
  def add_enum_values_and_modify_column_sql(enum_type_name, enum_type_values, table_name, column_name)
    when is_list(enum_type_values) and is_binary(enum_type_name) and is_binary(table_name) and is_binary(column_name) do
    if listing_status_types_contain?(enum_type_values) do
      IO.puts "Database contained at least one of the enum values in #{inspect enum_type_values} in enum #{enum_type_name}, skipping"
      []
    else
      [
        "DROP TYPE IF EXISTS #{enum_type_name}_temp",
        "CREATE TYPE #{enum_type_name}_temp AS ENUM (#{singly_quoted_list(enum_type_values)})",
        "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} TYPE #{enum_type_name}_temp USING (#{column_name}::text::#{enum_type_name}_temp)",
        "DROP TYPE #{enum_type_name}",
        "ALTER TYPE #{enum_type_name}_temp RENAME TO #{enum_type_name}",
        "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} TYPE #{enum_type_name} USING (#{column_name}::text::#{enum_type_name})"
      ]
    end
  end

  # Needed to make updating these idempotent
  alias Mpnetwork.Repo
  def get_current_listing_status_types_from_db() do
    {:ok, %Postgrex.Result{num_rows: 1, rows: [[listing_status_types]]}} = Repo.query("select enum_range(null::listing_status_type);")
    listing_status_types
  end

  def listing_status_types_contain?(listing_status_type) when is_binary(listing_status_type) do
    Enum.member?(get_current_listing_status_types_from_db(), listing_status_type)
  end
  def listing_status_types_contain?(listing_status_types) when is_list(listing_status_types) do
    current_status_types = get_current_listing_status_types_from_db()
    new_status_types = listing_status_types -- current_status_types
    new_status_types == []
  end

  # Drop a single enum value at a time, citing what value to convert any row using that value to.
  def drop_enum_value_and_modify_column_sql(enum_type_name, enum_type_values, enum_type_deleted_value, value_to_change_removed_values_to, table_name, column_name)
    when is_list(enum_type_values) and is_binary(enum_type_name) and is_binary(enum_type_deleted_value) and is_binary(table_name) and is_binary(column_name) do
    # makes this idempotent. won't try to delete an enum value if it isn't there
    if listing_status_types_contain?(enum_type_deleted_value) do
      [
        "DROP TYPE IF EXISTS #{enum_type_name}_temp",
        "CREATE TYPE #{enum_type_name}_temp AS ENUM (#{singly_quoted_list(enum_type_values)})",
        "UPDATE #{table_name} SET #{column_name} = #{if value_to_change_removed_values_to, do: "'"<>value_to_change_removed_values_to<>"'", else: "NULL"} WHERE #{column_name} = '#{enum_type_deleted_value}'",
        "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} TYPE #{enum_type_name}_temp USING (#{column_name}::text::#{enum_type_name}_temp)",
        "DROP TYPE #{enum_type_name}",
        "ALTER TYPE #{enum_type_name}_temp RENAME TO #{enum_type_name}",
        "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} TYPE #{enum_type_name} USING (#{column_name}::text::#{enum_type_name})"
      ]
    else
      IO.puts "Database did not contain enum value #{enum_type_deleted_value} in enum #{enum_type_name}"
      []
    end
  end

  def force_search_reindex_sql(schema_state) do
    field = first_field_name(schema_state)
    ["UPDATE listings SET #{field} = #{field}"]
  end

  def execute_all([statement | other_statements]) when is_binary(statement) do
    Ecto.Migration.execute(statement)
    execute_all(other_statements)
  end
  def execute_all([statements | other_statements]) when is_list(statements) do
    execute_all(statements)
    execute_all(other_statements)
  end
  def execute_all([]), do: nil

end
