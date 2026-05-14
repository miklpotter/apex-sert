-- run Liquibase to install/update SERT in standalone mode (no platform)
-- sert base schema must be created so that lb control tables will not be created in ADMIN/SYS schema
-- if it is a PDB, then tablespace DATA must exists
set feedback     off
set define       off
set linesize     300
set pagesize     1000
set serveroutput on size unlimited
set sqlformat    default
set termout      on
set timing       off
set verify       off

-- Note: SQL behavior for install error will abort with error.
whenever sqlerror exit fail

liquibase update -changelog-file product/sert/pre-install/base_schema.sql -database-changelog-table-name sert_databasechangelog -defaults-file sert.properties
-- run liquibase
liquibase update -changelog-file controller.xml -database-changelog-table-name sert_databasechangelog -default-schema-name sert_core -contexts runtime,standalone,apex
prompt == ===========================================================
PROMPT == RUN NONPROD SCRIPTS
prompt == ===========================================================

liquibase update -changelog-file nonprod/nonProdController.xml -database-changelog-table-name sert_databasechangelog -defaults-file sert.properties -default-schema-name sert_core 
