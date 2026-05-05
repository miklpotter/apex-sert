--liquibase formatted sql
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown
-- at https://oss.oracle.com/licenses/upl/
--------------------------------------------------------------------------------

--changeset mipotter:create_auto_scan_job_1715115600002 endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from user_scheduler_jobs where job_name = 'SERT_AUTO_SCAN_JOB';

declare
  l_job_exists number;
begin
  -- Check if job already exists (in case of re-run)
  select count(1) into l_job_exists
    from user_scheduler_jobs
   where job_name = 'SERT_AUTO_SCAN_JOB';

  if l_job_exists > 0 then
    -- Drop existing job to recreate it
    begin
      dbms_scheduler.drop_job(job_name => 'SERT_AUTO_SCAN_JOB', force => true);
    exception
      when others then
        if sqlcode != -27475 then  -- Object does not exist
          raise;
        end if;
    end;
  end if;

  -- Create the daily auto-scan job
  -- Scheduled for 2 AM UTC every day to run off-peak
  dbms_scheduler.create_job(
    job_name        => 'SERT_AUTO_SCAN_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'!
declare
  l_app_count number;
begin
  sert_core.schedule_api.queue_auto_scans(
    p_batch_size     => 20,
    p_app_count_out  => l_app_count
  );
  sert_core.log_pkg.log(
    p_log => 'Auto-scan job completed: ' || l_app_count || ' applications queued',
    p_log_type => 'INFO'
  );
end;
!',
    repeat_interval => 'FREQ=DAILY;BYHOUR=2;BYMINUTE=0',  -- Every day at 2 AM UTC
    enabled         => false,                             -- Disabled by default; DBA must enable
    comments        => 'Automated daily scan of stale and unscanned applications, ranked by recent activity'
  );

end;
/
--rollback drop job SERT_AUTO_SCAN_JOB
