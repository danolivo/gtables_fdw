/* contrib/gtables_fdw/gtables_fdw--0.1.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION gtables_fdw" to load this file. \quit

DROP SCHEMA IF EXISTS gt CASCADE;
CREATE SCHEMA IF NOT EXISTS gt;

CREATE TABLE gt.GlobalTables (
	id serial NOT NULL,
	-- Link to the pg_foreign_server table
	tblname name PRIMARY KEY
);

CREATE TABLE gt.GlobalTableSpace (
	id serial NOT NULL,
	-- Link to the pg_foreign_server table
	srvname name PRIMARY KEY
);

--
-- Add new foreign server into global table space. Perform precheck of the
-- foreign server existence into the pg_foreign_server table.
--
CREATE OR REPLACE FUNCTION gt.addForeignServer(srvname name)
RETURNS bool AS $$
BEGIN
	SELECT EXISTS (SELECT 1 FROM pg_foreign_server WHERE srvname=$1) INTO found;

	IF found <> 't' THEN
		RAISE EXCEPTION 'Несуществующий Foreign server: %', $1;
	END IF;

	SELECT EXISTS (SELECT 1 FROM gt.GlobalTableSpace WHERE srvname=$1) INTO found;
	IF found == 't' THEN
	   	RAISE EXCEPTION 'Дублирующий Foreign server: %', $1;
	END IF;

	INSERT INTO gt.GlobalTableSpace (srvname) VALUES (srvname);
	RETURN true;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gt.AddGlobalTable()
RETURNS trigger AS $$
DECLARE
	ftbl := New.tblname + "_1";
BEGIN
	CREATE FOREIGN TABLE ftbl SERVER remote;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER OnAddGlobalTable BEFORE INSERT
	ON  gt.GlobalTables FOR EACH STATEMENT
	EXECUTE PROCEDURE gt.AddGlobalTable();
