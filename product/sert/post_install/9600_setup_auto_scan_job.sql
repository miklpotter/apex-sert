--liquibase formatted sql
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown
-- at https://oss.oracle.com/licenses/upl/
--------------------------------------------------------------------------------

--changeset mipotter:create_auto_scan_job_1715115600002 endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
begin
  sert_core.schedule_api.setup_auto_scan_job(
    p_frequency => upper(nvl('${sert_auto_scan_frequency}', 'HOURLY')),
    p_interval  => nvl('${sert_auto_scan_interval}', '1')
  );
end;
/
--rollback not required
