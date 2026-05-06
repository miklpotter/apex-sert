--liquibase formatted sql
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown
-- at https://oss.oracle.com/licenses/upl/
--------------------------------------------------------------------------------

--changeset mipotter:create_auto_scan_job_1715115600002 endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
declare
  l_frequency       varchar2(10)  := upper(nvl('${sert_auto_scan_frequency}', 'HOURLY'));
  l_interval        varchar2(3)   := nvl('${sert_auto_scan_interval}', '1');
  l_repeat_interval varchar2(100);
begin
  -- Validate frequency; default to HOURLY if invalid
  if l_frequency not in ('MINUTELY', 'HOURLY', 'DAILY') then
    l_frequency := 'HOURLY';
  end if;

  -- Validate interval (1-99); default to 1 if invalid
  if not regexp_like(l_interval, '^\d{1,2}$') or
     to_number(l_interval) < 1 or to_number(l_interval) > 99 then
    l_interval := '1';
  end if;

  l_repeat_interval := 'FREQ=' || l_frequency || ';INTERVAL=' || l_interval;

  -- Drop existing job to recreate with updated settings
  begin
    dbms_scheduler.drop_job(job_name => 'SERT_AUTO_SCAN_JOB', force => true);
  exception
    when others then
      if sqlcode != -27475 then  -- ORA-27475: object does not exist
        raise;
      end if;
  end;

  dbms_scheduler.create_job(
    job_name        => 'SERT_AUTO_SCAN_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'!
declare
  l_app_count number;
begin
  sert_core.schedule_api.queue_auto_scans(
    p_app_count_out => l_app_count
  );
  sert_core.log_pkg.log(
    p_log      => 'Auto-scan job completed: ' || l_app_count || ' applications queued',
    p_log_type => 'INFO'
  );
end;
!',
    repeat_interval => l_repeat_interval,
    enabled         => false,   -- DBA must enable when ready
    comments        => 'Automated scan of stale and unscanned applications, ranked by recent activity'
  );

end;
/
--rollback drop job SERT_AUTO_SCAN_JOB
