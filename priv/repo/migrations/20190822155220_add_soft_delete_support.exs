defmodule Mpnetwork.Repo.Migrations.AddSoftDeleteSupport do
  use Ecto.Migration

  def change do
    execute(
      # up
      """
      DO $$
      BEGIN
        CREATE SCHEMA IF NOT EXISTS without_softdeleted;
        CREATE OR REPLACE FUNCTION "public"."logical_delete"()
        RETURNS "pg_catalog"."trigger" AS
        $BODY$
          BEGIN
            EXECUTE 'INSERT INTO ' || TG_TABLE_NAME || ' SELECT $1.*' USING OLD;
            EXECUTE 'UPDATE ' || TG_TABLE_NAME || ' SET deleted_at = current_timestamp where id = $1' USING OLD.id;
            RETURN OLD;
          END;
        $BODY$
        LANGUAGE plpgsql VOLATILE;
        CREATE OR REPLACE FUNCTION "public"."prepare_table_for_soft_delete"(text)
        RETURNS "pg_catalog"."void" AS
        $BODY$
          BEGIN
            EXECUTE 'ALTER TABLE ' || $1 || ' ADD COLUMN IF NOT EXISTS deleted_at timestamptz;';
            EXECUTE 'CREATE INDEX IF NOT EXISTS ' || $1 || '_not_deleted ON ' || $1 || ' (deleted_at) WHERE deleted_at IS NULL;';
            EXECUTE 'DROP TRIGGER IF EXISTS ' || $1 || '_logical_delete_tg ON ' || $1 || ';';
            EXECUTE 'CREATE TRIGGER ' || $1 || '_logical_delete_tg AFTER DELETE ON ' || $1 || ' FOR EACH ROW EXECUTE PROCEDURE logical_delete();';
            EXECUTE 'CREATE OR REPLACE VIEW without_softdeleted.' || $1 || ' AS SELECT * FROM ' || $1 || ' WHERE deleted_at IS NULL;';
          END;
        $BODY$
        LANGUAGE plpgsql VOLATILE;
        CREATE OR REPLACE FUNCTION "public"."reverse_table_soft_delete"(text)
        RETURNS "pg_catalog"."void" AS
        $BODY$
          BEGIN
            EXECUTE 'DROP VIEW IF EXISTS without_softdeleted.' || $1 || ';';
            EXECUTE 'DROP TRIGGER IF EXISTS ' || $1 || '_logical_delete_tg ON ' || $1 || ';';
            EXECUTE 'DROP INDEX IF EXISTS ' || $1 || '_not_deleted;';
            EXECUTE 'ALTER TABLE ' || $1 || ' DROP COLUMN IF EXISTS deleted_at;';
          END;
        $BODY$
        LANGUAGE plpgsql VOLATILE;
      END $$
      """,
      # down
      """
      DO $$
      BEGIN
        DROP FUNCTION IF EXISTS logical_delete();
        DROP FUNCTION IF EXISTS prepare_table_for_soft_delete(text);
        DROP FUNCTION IF EXISTS reverse_table_soft_delete(text);
        DROP SCHEMA IF EXISTS without_softdeleted CASCADE;
      END $$
      """
    )
  end
end
