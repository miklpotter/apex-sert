set define ^
set verify off
set serveroutput on

define sert_base_schema  = '&1'

-- liquibase status -changelog-file userController.xml -contexts sdk,standalone
-- liquibase status -changelog-file controller.xml -database-changelog-table-name sertchangelog -default-schema-name ^sert_base_schema -contexts runtime,standalone
liquibase validate -changelog-file controller.xml -database-changelog-table-name sertchangelog -default-schema-name ^sert_base_schema -contexts runtime,standalone

-- sed 's/\.sql//;s/^..._dml_//')