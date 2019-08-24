defmodule Mpnetwork.Repo.Migrations.AddSoftDeleteSupport do
  use Ecto.Migration

  def change do
    execute(
      # up
      """
      DO $$
      BEGIN
        CREATE SCHEMA without_softdeleted;
        CREATE FUNCTION "public"."logical_delete"()
        RETURNS "pg_catalog"."trigger" AS
        $BODY$
          BEGIN
            EXECUTE 'INSERT INTO ' || TG_TABLE_NAME || ' SELECT $1.*' USING OLD;
            EXECUTE 'UPDATE ' || TG_TABLE_NAME || ' SET deleted_at = current_timestamp where id = $1' USING OLD.id;
            RETURN OLD;
          END;
        $BODY$
        LANGUAGE plpgsql VOLATILE;
        CREATE FUNCTION "public"."prepare_table_for_soft_delete"(text)
        RETURNS "pg_catalog"."void" AS
        $BODY$
          BEGIN
            EXECUTE 'ALTER TABLE ' || $1 || ' ADD COLUMN deleted_at timestamptz;';
            EXECUTE 'CREATE INDEX ' || $1 || '_not_deleted ON ' || $1 || ' (deleted_at) WHERE deleted_at IS NULL;';
            EXECUTE 'CREATE TRIGGER ' || $1 || '_logical_delete_tg AFTER DELETE ON ' || $1 || ' FOR EACH ROW EXECUTE PROCEDURE logical_delete();';
            EXECUTE 'CREATE VIEW without_softdeleted.' || $1 || ' AS SELECT * FROM ' || $1 || ' WHERE deleted_at IS NULL;';
          END;
        $BODY$
        LANGUAGE plpgsql VOLATILE;
        CREATE FUNCTION "public"."reverse_table_soft_delete"(text)
        RETURNS "pg_catalog"."void" AS
        $BODY$
          BEGIN
            EXECUTE 'DROP VIEW without_softdeleted.' || $1 || ';';
            EXECUTE 'DROP TRIGGER ' || $1 || '_logical_delete_tg ON ' || $1 || ';';
            EXECUTE 'DROP INDEX ' || $1 || '_not_deleted;';
            EXECUTE 'ALTER TABLE ' || $1 || ' DROP COLUMN deleted_at;';
          END;
        $BODY$
        LANGUAGE plpgsql VOLATILE;
      END $$
      """,
      # down
      """
      DO $$
      BEGIN
        DROP FUNCTION logical_delete();
        DROP FUNCTION prepare_table_for_soft_delete(text);
        DROP FUNCTION reverse_table_soft_delete(text);
        DROP SCHEMA without_softdeleted;
      END $$
      """
    )
  end
end
