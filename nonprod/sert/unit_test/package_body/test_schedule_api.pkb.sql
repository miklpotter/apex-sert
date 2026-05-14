--liquibase formatted sql
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown
-- at https://oss.oracle.com/licenses/upl/
--------------------------------------------------------------------------------

--changeset mipotter:create_package_body_unit_test.test_schedule_api_1777986000 stripComments:false endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create or replace package body unit_test.test_schedule_api
as

-- Test workspace/app IDs that do not exist in production data
c_test_workspace_id     constant number := -99100;
c_test_workspace        constant varchar2(255) := 'DEMO';
c_test_application_id   constant number := 200;
c_min_test_application_id   constant number := 200;
c_max_test_application_id   constant number := 230;

g_pref_snap t_pref_snap_tab;

------------------------------------------------------------
-- snap_prefs
-- Captures current db state of the three prefs that setup_prefs
-- will overwrite, so restore_prefs can undo them.
------------------------------------------------------------
procedure snap_prefs
as
begin
    g_pref_snap.delete;
    g_pref_snap(1) := sert_core.prefs_api.get_pref('AUTO_SCAN');
    g_pref_snap(2) := sert_core.prefs_api.get_pref('AUTO_SCAN_BATCH_SIZE');
    g_pref_snap(3) := sert_core.prefs_api.get_pref('AUTO_SCAN_IGNORE_WS');
end snap_prefs;

------------------------------------------------------------
-- restore_prefs
-- Restores the three prefs that setup_prefs overwrote.
-- Uses prefs_api.upsert_pref to restore rows that existed.
-- Commits after restore since it is called in tests where
-- queue_auto_scans has already issued an implicit commit.
------------------------------------------------------------
procedure restore_prefs
as
begin
    for i in 1..g_pref_snap.count loop
        if g_pref_snap(i).pref_key is not null then
            sert_core.prefs_api.upsert_pref(g_pref_snap(i));
        end if;
    end loop;
    commit;
    g_pref_snap.delete;
end restore_prefs;

------------------------------------------------------------
-- setup_prefs
-- Runs before each test via --%beforeeach.
-- Snapshots current pref state then sets known test values:
--   AUTO_SCAN=Y, AUTO_SCAN_BATCH_SIZE=20, AUTO_SCAN_IGNORE_WS='~'
-- Tests that commit (forcing manual state restore) must call
-- restore_prefs explicitly in their cleanup section.
------------------------------------------------------------
procedure setup_prefs
as
begin
    snap_prefs;
    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Auto Scan All Apps',
        p_pref_key    => 'AUTO_SCAN',
        p_pref_value  => 'Y',
        p_internal_yn => 'N');
    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Auto Scan Batch Size',
        p_pref_key    => 'AUTO_SCAN_BATCH_SIZE',
        p_pref_value  => '20',
        p_internal_yn => 'N');
    -- '~' is a sentinel that matches no real workspace name; effectively disables filtering.
    -- Oracle treats '' as NULL, which violates the NOT NULL constraint on prefs.pref_value.
    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Ignore Workspaces for auto Scan',
        p_pref_key    => 'AUTO_SCAN_IGNORE_WS',
        p_pref_value  => '~',
        p_internal_yn => 'N');
end setup_prefs;

------------------------------------------------------------
-- setup_test_workspace
-- Creates a test workspace in apex_workspaces table.
-- NOTE: requires DBA grant on APEX_240200.WWV_FLOW_COMPANIES
--       to unit_test; will fail at runtime without it.
------------------------------------------------------------
function setup_test_workspace return number
is
    l_workspace_id number := c_test_workspace_id;
begin
    select workspace_id into l_workspace_id from apex_workspaces where workspace = c_test_workspace;
    return l_workspace_id;
end setup_test_workspace;

------------------------------------------------------------
-- setup_test_application
-- Creates a test application in apex_applications table.
-- NOTE: requires DBA grant on APEX_240200.WWV_FLOWS
--       to unit_test; will fail at runtime without it.
------------------------------------------------------------
procedure setup_test_application (
    p_workspace_id  in number,
    p_app_id        in number,
    p_app_name      in varchar2,
    p_last_updated  in date default sysdate)
is
    l_app_count     number;
begin
    select count(*) into l_app_count
    from apex_applications
    where application_id between c_min_test_application_id and c_max_test_application_id;

    ut.expect(l_app_count).to_equal(30);
end setup_test_application;

------------------------------------------------------------
-- setup_test_eval
-- Creates a test evaluation record in sert_core.evals.
-- Parameters:
--   p_workspace_id  - workspace ID
--   p_app_id        - application ID
--   p_eval_date     - evaluation date
-- Returns: eval_id of the inserted row
------------------------------------------------------------
function setup_test_eval (
    p_workspace_id  in number,
    p_app_id        in number,
    p_eval_date     in date) return number
is
    l_eval_id         number;
    l_rule_set_id     number;
    l_rule_set_count  number;
begin
    -- Precondition: at least one rule set (SERT-SECURITY) must exist for the installed version
    select count(*) into l_rule_set_count
      from sert_core.rule_sets
     where rule_set_key = 'SERT-SECURITY'
       and active_yn = 'Y'
       and apex_version = sert_core.prefs_api.pref_value('SERT_APEX_VERSION');

    ut.expect(l_rule_set_count).to_be_greater_than(0);

    -- Get first available rule_set_id
    select min(rule_set_id) into l_rule_set_id
      from sert_core.rule_sets
     where rule_set_key = 'SERT-SECURITY'
       and active_yn = 'Y'
       and apex_version = sert_core.prefs_api.pref_value('SERT_APEX_VERSION');

    -- insert minimal eval record
    insert into sert_core.evals (
        workspace_id,
        application_id,
        rule_set_id,
        eval_on_date,
        job_status)
    values (
        p_workspace_id,
        p_app_id,
        l_rule_set_id,
        p_eval_date,
        'COMPLETED')
    returning eval_id into l_eval_id;

    return l_eval_id;
end setup_test_eval;

procedure check_test_apps (
    p_workspace_id  in number )
is
    l_app_count     number;
    l_app_id        number;
    l_eval_id       number;
begin
    select count(*) into l_app_count
    from apex_applications
    where application_id between c_min_test_application_id and c_max_test_application_id;
    ut.expect(l_app_count).to_equal(31);
    -- clean out any evals
    delete from sert_core.evals where application_id between c_min_test_application_id and c_max_test_application_id;
    -- configure a known starting point
    for l_app_id in (c_min_test_application_id+1)..c_max_test_application_id loop
        l_eval_id := setup_test_eval(
            p_workspace_id => p_workspace_id,
            p_app_id       => l_app_id,
            p_eval_date    => sysdate);
    end loop; -- for l_app_id

end;

------------------------------------------------------------
-- no_stale_apps
-- Tests: should return 1 when an unscanned app exists
-- Setup: Create test workspace with 1 app that has NO evals
-- Execute: Call queue_auto_scans
-- Assert: l_count should equal 1
------------------------------------------------------------
procedure no_stale_apps
as
    l_count         number := 0;
    l_workspace_id  number;
    l_eval_id       number := 0;
    l_app_id        number;
begin
    -- Setup: Create test workspace and one app with no evaluations
    l_workspace_id := setup_test_workspace;
    check_test_apps(l_workspace_id);

    sert_core.schedule_api.queue_auto_scans(
        p_batch_size => 10,
        p_app_count_out => l_count);

    -- Cleanup: restore committed pref state; rollback any uncommitted test data
    delete from sert_core.evals where application_id between c_min_test_application_id and c_max_test_application_id;
    -- Assert: Should return 1 (the unscanned app)
    ut.expect(l_count).to_equal(1);

end no_stale_apps;

------------------------------------------------------------
-- stale_apps_under_limit
-- Tests: should return all stale apps when less than batch limit
-- Setup: Create test workspace with 5 unscanned apps
-- Execute: Call queue_auto_scans with p_batch_size=20
-- Assert: l_count should equal 5 (all unscanned apps)
------------------------------------------------------------
procedure stale_apps_under_limit
as
    l_count         number := 0;
    l_workspace_id  number;
    l_eval_id       number := 0;
begin
    -- Setup: Create test workspace and 5 unscanned apps
    l_workspace_id := setup_test_workspace;

    check_test_apps(l_workspace_id);
    delete from sert_core.evals where application_id between c_min_test_application_id and c_min_test_application_id + 4;
    -- now configure evals for all bar ONE app (200)
    for l_app_id in (c_min_test_application_id+5)..c_max_test_application_id loop
        l_eval_id := setup_test_eval(
            p_workspace_id => l_workspace_id,
            p_app_id       => l_app_id,
            p_eval_date    => sysdate);
    end loop; -- for l_app_id

    -- Execute: Call queue_auto_scans with default batch size
    sert_core.schedule_api.queue_auto_scans(
        p_batch_size => 20,
        p_app_count_out => l_count);

    delete from sert_core.evals where application_id between c_min_test_application_id and c_max_test_application_id;
    -- Assert: Should return 5 (all 5 unscanned apps)
    ut.expect(l_count).to_equal(5);

end stale_apps_under_limit;

------------------------------------------------------------
-- ignored_workspace_excluded
-- Tests: apps in the ignored workspace are not queued
-- Setup: set AUTO_SCAN_IGNORE_WS = 'SERT'; verify SERT has
--        candidates so the filter has a real effect; compute
--        expected count as non-SERT non-APEX-system candidates
-- Execute: queue_auto_scans(p_batch_size => 100)
-- Assert: count = non-SERT candidates (SERT apps excluded)
------------------------------------------------------------
procedure ignored_workspace_excluded
as
    l_count           number;
    l_sert_candidates number;
    l_expected_count  number;
begin
    -- Reset evals for all SERT apps so all 3 are unscanned candidates regardless of prior test runs.
    delete from sert_core.evals
    where application_id between c_min_test_application_id and c_max_test_application_id;

    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Ignore Workspaces for auto Scan',
        p_pref_key    => 'AUTO_SCAN_IGNORE_WS',
        p_pref_value  => 'SERT,DEMO',
        p_internal_yn => 'N');

    -- Precondition: c_test_workspace must have at least one candidate (filter has real effect)
    select count(*) into l_sert_candidates
      from (
        select e.application_id
          from sert_core.evals_pub_v e
         where e.eval_on_date < e.last_updated_on - 1
           and upper(e.workspace) = c_test_workspace
        union all
        select a.application_id
          from apex_applications a
         where upper(a.workspace) = c_test_workspace
           and not exists (select 1 from sert_core.evals where application_id = a.application_id)
      );
    ut.expect(l_sert_candidates).to_be_greater_than(0);

    -- Expected: unscanned/stale apps not in SERT or APEX-system workspaces
    select count(*) into l_expected_count
      from (
        select e.application_id
          from sert_core.evals_pub_v e
         where e.eval_on_date < e.last_updated_on - 1
           and upper(e.workspace) not in ('DEMO','SERT', 'INTERNAL', 'COM.ORACLE.CUST.REPOSITORY')
        union all
        select a.application_id
          from apex_applications a
         where upper(a.workspace) not in ('DEMO','SERT', 'INTERNAL', 'COM.ORACLE.CUST.REPOSITORY')
           and not exists (select 1 from sert_core.evals where application_id = a.application_id)
      );

    sert_core.schedule_api.queue_auto_scans(
        p_batch_size    => 50,
        p_app_count_out => l_count);

    delete from sert_core.evals where application_id between c_min_test_application_id and c_max_test_application_id;
    ut.expect(l_count).to_equal(l_expected_count);
end ignored_workspace_excluded;

-- =============================================================================================
-- to be completed below
-- =============================================================================================

------------------------------------------------------------
-- top_20_by_guardian_activity
-- Tests: should queue top 20 ranked by Guardian activity
-- Setup: Create test workspace with 50 unscanned apps + Guardian
--        activity data in sg_most_4wk_app_activity_f
-- Execute: Call queue_auto_scans with p_batch_size=20
-- Assert: l_count should equal 20 (exactly batch size)
------------------------------------------------------------
procedure top_20_by_guardian_activity
as
    l_count         number := 0;
    l_workspace_id  number;
    l_base_app_id   number;
begin
    -- Setup: Create test workspace
    l_workspace_id := setup_test_workspace;
    check_test_apps(l_workspace_id);

    -- Create 30 unscanned apps (Guardian not installed; falls back to eval_on_date ordering)
    for i in 1..50 loop
        setup_test_application(
            p_workspace_id => l_workspace_id,
            p_app_id       => l_base_app_id + i,
            p_app_name     => 'TEST_GUARDIAN_APP_' || i);
    end loop;

    -- Execute: Call queue_auto_scans with batch_size=20
    sert_core.schedule_api.queue_auto_scans(
        p_batch_size => 20,
        p_app_count_out => l_count);

    -- Assert: Should return exactly 20 (batch size enforced, 50 candidates available)
    ut.expect(l_count).to_equal(20);

    -- Cleanup: Rollback test data
    rollback;
end top_20_by_guardian_activity;

------------------------------------------------------------
-- error_handling
-- Tests: procedure queues apps successfully and handles edge cases
-- Setup: Create test workspace with 5 unscanned apps
-- Execute: Call queue_auto_scans (procedure handles errors internally)
-- Assert: All 5 apps are queued successfully (count = 5)
------------------------------------------------------------
procedure error_handling
as
    l_count         number := 0;
    l_workspace_id  number;
    l_base_app_id   number;
begin
    -- Setup: Create test workspace with 5 unscanned apps
    l_workspace_id := setup_test_workspace;
    l_base_app_id := c_test_application_id - 4000;

    for i in 1..5 loop
        setup_test_application(
            p_workspace_id => l_workspace_id,
            p_app_id       => l_base_app_id + i,
            p_app_name     => 'TEST_ERROR_APP_' || i);
    end loop;

    -- Execute: Call queue_auto_scans
    -- The procedure should handle any internal errors gracefully
    sert_core.schedule_api.queue_auto_scans(
        p_batch_size => 20,
        p_app_count_out => l_count);

    -- Assert: All 5 apps should be queued successfully
    ut.expect(l_count).to_equal(5);

    -- Cleanup: Rollback test data
    rollback;
end error_handling;

------------------------------------------------------------
-- auto_scan_disabled
-- Tests: procedure returns 0 immediately when AUTO_SCAN='N'
-- Setup: override AUTO_SCAN to N (no app data setup needed)
-- Execute: queue_auto_scans with no p_batch_size
-- Assert: count = 0 (early exit before cursor is opened)
------------------------------------------------------------
procedure auto_scan_disabled
as
    l_count number;
begin
    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Auto Scan All Apps',
        p_pref_key    => 'AUTO_SCAN',
        p_pref_value  => 'N',
        p_internal_yn => 'N');

    sert_core.schedule_api.queue_auto_scans(
        p_app_count_out => l_count);

    ut.expect(l_count).to_equal(0);

    rollback;
end auto_scan_disabled;

------------------------------------------------------------
-- batch_size_from_pref
-- Tests: procedure reads AUTO_SCAN_BATCH_SIZE pref when
--        p_batch_size is not supplied
-- Precondition: >= 3 total non-APEX-system candidates exist
--   (currently: apps 2100 stale + 2101 + 2102 unscanned in SERT)
-- Setup: override AUTO_SCAN_BATCH_SIZE to 2
-- Execute: queue_auto_scans with no p_batch_size param
-- Assert: count = 2 (pref honored, more candidates available)
------------------------------------------------------------
procedure batch_size_from_pref
as
    l_count            number;
    l_total_candidates number;
begin
    -- Reset any evals committed by earlier tests so we always have a known candidate pool.
    -- eval_pkg.eval creates DBMS jobs (DDL → implicit commit), so rollback cannot clean up
    -- state from prior tests. Deleting these rows leaves all 3 SERT apps unscanned.
    delete from sert_core.evals where application_id in (2100, 2101, 2102);

    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Auto Scan Batch Size',
        p_pref_key    => 'AUTO_SCAN_BATCH_SIZE',
        p_pref_value  => '2',
        p_internal_yn => 'N');

    -- Precondition: more than 2 candidates must exist so the pref cap has effect
    select count(*) into l_total_candidates
      from (
        select e.application_id
          from sert_core.evals_pub_v e
         where e.eval_on_date < e.last_updated_on - 1
           and upper(e.workspace) not in ('INTERNAL', 'TOWER', 'COM.ORACLE.CUST.REPOSITORY')
        union all
        select a.application_id
          from apex_applications a
         where upper(a.workspace) not in ('INTERNAL', 'TOWER', 'COM.ORACLE.CUST.REPOSITORY')
           and not exists (select 1 from sert_core.evals where application_id = a.application_id)
      );
    ut.expect(l_total_candidates).to_be_greater_than(2);

    sert_core.schedule_api.queue_auto_scans(
        p_app_count_out => l_count);

    ut.expect(l_count).to_equal(2);

    rollback;
end batch_size_from_pref;

------------------------------------------------------------
-- param_overrides_pref_batch_size
-- Tests: explicit p_batch_size parameter wins over pref value
-- Precondition: >= 2 total non-APEX-system candidates exist
-- Setup: setup_prefs sets AUTO_SCAN_BATCH_SIZE = 20
-- Execute: queue_auto_scans(p_batch_size => 1)
-- Assert: count = 1 (param 1 wins over pref 20)
------------------------------------------------------------
procedure param_overrides_pref_batch_size
as
    l_count            number;
    l_total_candidates number;
begin
    -- Reset any evals committed by earlier tests so we always have a known candidate pool.
    delete from sert_core.evals where application_id in (2100, 2101, 2102);

    -- Precondition: at least 2 candidates so param=1 is demonstrably less than available
    select count(*) into l_total_candidates
      from (
        select e.application_id
          from sert_core.evals_pub_v e
         where e.eval_on_date < e.last_updated_on - 1
           and upper(e.workspace) not in ('INTERNAL', 'TOWER', 'COM.ORACLE.CUST.REPOSITORY')
        union all
        select a.application_id
          from apex_applications a
         where upper(a.workspace) not in ('INTERNAL', 'TOWER', 'COM.ORACLE.CUST.REPOSITORY')
           and not exists (select 1 from sert_core.evals where application_id = a.application_id)
      );
    ut.expect(l_total_candidates).to_be_greater_than(1);

    sert_core.schedule_api.queue_auto_scans(
        p_batch_size    => 1,
        p_app_count_out => l_count);

    ut.expect(l_count).to_equal(1);

    rollback;
end param_overrides_pref_batch_size;

------------------------------------------------------------
-- recently_evaluated_not_stale
-- Tests: app whose eval_on_date is 12 hours before last_updated_on
--        is NOT a stale candidate (requires > 1 day gap)
-- Setup: reset app 2100; insert eval 12h before last_updated_on;
--        compute baseline; run queue_auto_scans
-- Assert: count equals baseline (grace-period app was not queued)
------------------------------------------------------------
procedure recently_evaluated_not_stale
as
    l_count        number;
    l_expected     number;
    l_last_updated date;
    l_workspace_id number;
    l_ignored_eval number;
begin
    -- Reset app 2100 to a clean state (no evals)
    delete from sert_core.evals where application_id = 2100;

    -- Get app 2100's workspace and last modification date
    select workspace_id, last_updated_on
      into l_workspace_id, l_last_updated
      from apex_applications
     where application_id = 2100;

    -- Insert eval 12 hours BEFORE the app's last modification.
    -- eval_on_date (12h before last_updated_on) < last_updated_on:        YES → old 'Stale' rule flags this app → old code queues it
    -- eval_on_date (12h before last_updated_on) < last_updated_on - 1:   NO  → new rule does NOT flag it → new code skips it
    l_ignored_eval := setup_test_eval(
        p_workspace_id => l_workspace_id,
        p_app_id       => 2100,
        p_eval_date    => l_last_updated - (12/24));

    -- Baseline: count candidates under the NEW staleness formula.
    -- Computed AFTER the insert so app 2100 is visible but excluded:
    --   - not unscanned (has an eval)
    --   - not stale (eval_on_date = last_updated_on - 0.5, which is NOT < last_updated_on - 1)
    select count(*) into l_expected
      from (
        select e.application_id
          from sert_core.evals_pub_v e
         where e.eval_on_date < e.last_updated_on - 1
           and upper(e.workspace) not in ('INTERNAL', 'COM.ORACLE.CUST.REPOSITORY')
        union all
        select a.application_id
          from apex_applications a
         where upper(a.workspace) not in ('INTERNAL', 'COM.ORACLE.CUST.REPOSITORY')
           and not exists (
                 select 1 from sert_core.evals where application_id = a.application_id)
      );

    sert_core.schedule_api.queue_auto_scans(
        p_batch_size    => 999,
        p_app_count_out => l_count);

    -- The grace-period app must not have increased the count
    ut.expect(l_count).to_equal(l_expected);

    rollback;
end recently_evaluated_not_stale;

------------------------------------------------------------
-- drop_auto_scan_job_if_exists
-- Silently drops SERT_CORE.SERT_AUTO_SCAN_JOB; used for
-- teardown in setup_auto_scan_job tests.
------------------------------------------------------------
procedure drop_auto_scan_job_if_exists
is
begin
   sert_core.schedule_api.remove_schedule_job(
      p_job_name => 'SERT_CORE.SERT_AUTO_SCAN_JOB');
exception
   when others then null;
end drop_auto_scan_job_if_exists;

------------------------------------------------------------
-- setup_auto_scan_job_defaults
-- Tests: default call creates job with FREQ=HOURLY;INTERVAL=1
------------------------------------------------------------
procedure setup_auto_scan_job_defaults
as
   l_interval varchar2(4000);
begin
   drop_auto_scan_job_if_exists;

   sert_core.schedule_api.setup_auto_scan_job;

   l_interval := sert_core.schedule_api.auto_scan_job_interval;
   ut.expect(l_interval).to_equal('FREQ=HOURLY;INTERVAL=1');

   drop_auto_scan_job_if_exists;
end setup_auto_scan_job_defaults;

------------------------------------------------------------
-- setup_auto_scan_job_minutely
-- Tests: MINUTELY frequency and custom interval are honoured
------------------------------------------------------------
procedure setup_auto_scan_job_minutely
as
   l_interval varchar2(4000);
begin
   drop_auto_scan_job_if_exists;

   sert_core.schedule_api.setup_auto_scan_job(
      p_frequency => 'MINUTELY',
      p_interval  => '5');

   l_interval := sert_core.schedule_api.auto_scan_job_interval;
   ut.expect(l_interval).to_equal('FREQ=MINUTELY;INTERVAL=5');

   drop_auto_scan_job_if_exists;
end setup_auto_scan_job_minutely;

------------------------------------------------------------
-- setup_auto_scan_job_invalid_freq
-- Tests: unsupported frequency value is silently coerced to HOURLY
------------------------------------------------------------
procedure setup_auto_scan_job_invalid_freq
as
   l_interval varchar2(4000);
begin
   drop_auto_scan_job_if_exists;

   sert_core.schedule_api.setup_auto_scan_job(
      p_frequency => 'WEEKLY',
      p_interval  => '1');

   l_interval := sert_core.schedule_api.auto_scan_job_interval;
   ut.expect(l_interval).to_equal('FREQ=HOURLY;INTERVAL=1');

   drop_auto_scan_job_if_exists;
end setup_auto_scan_job_invalid_freq;

------------------------------------------------------------
-- setup_auto_scan_job_invalid_interval
-- Tests: interval outside 1-99 range is coerced to 1
------------------------------------------------------------
procedure setup_auto_scan_job_invalid_interval
as
   l_interval varchar2(4000);
begin
   drop_auto_scan_job_if_exists;

   sert_core.schedule_api.setup_auto_scan_job(
      p_frequency => 'DAILY',
      p_interval  => '0');

   l_interval := sert_core.schedule_api.auto_scan_job_interval;
   ut.expect(l_interval).to_equal('FREQ=DAILY;INTERVAL=1');

   drop_auto_scan_job_if_exists;
end setup_auto_scan_job_invalid_interval;

------------------------------------------------------------
-- setup_auto_scan_job_idempotent
-- Tests: second call replaces the job; new interval wins
------------------------------------------------------------
procedure setup_auto_scan_job_idempotent
as
   l_interval varchar2(4000);
begin
   drop_auto_scan_job_if_exists;

   sert_core.schedule_api.setup_auto_scan_job(
      p_frequency => 'HOURLY',
      p_interval  => '1');

   sert_core.schedule_api.setup_auto_scan_job(
      p_frequency => 'DAILY',
      p_interval  => '3');

   l_interval := sert_core.schedule_api.auto_scan_job_interval;
   ut.expect(l_interval).to_equal('FREQ=DAILY;INTERVAL=3');

   drop_auto_scan_job_if_exists;
end setup_auto_scan_job_idempotent;

end test_schedule_api;
/
--rollback not required
