--liquibase formatted sql
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown
-- at https://oss.oracle.com/licenses/upl/
--------------------------------------------------------------------------------

--changeset mipotter:compile_sert_core.schedule_api_guardian_1778116500000 endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
alter package sert_core.schedule_api compile body plsql_ccflags = 'guardian_installed:true' reuse settings;
--rollback not required
