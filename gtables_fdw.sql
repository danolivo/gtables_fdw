/* contrib/file_fdw/file_fdw--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION gtables_fdw" to load this file. \quit

CREATE TABLE GlobalTableSpace (
	id serial NOT NULL PRIMARY KEY,
	Oid serverid
);
