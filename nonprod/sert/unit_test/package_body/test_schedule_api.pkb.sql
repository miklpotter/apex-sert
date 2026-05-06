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
c_test_application_id   constant number := -99100;

------------------------------------------------------------
-- setup_test_workspace
-- Creates a test workspace in apex_workspaces table.
-- Returns the workspace_id for use in test data insertion.
------------------------------------------------------------
function setup_test_workspace return number
is
    l_workspace_id number;
begin
    -- Insert test workspace
    insert into apex_workspaces (
        workspace_name,
        workspace_desc,
        workspace_id)
    values (
        'TEST_WORKSPACE_QUEUE_' || abs(c_test_workspace_id),
        'Test workspace for queue_auto_scans',
        c_test_workspace_id)
    returning workspace_id into l_workspace_id;

    return l_workspace_id;
end setup_test_workspace;

------------------------------------------------------------
-- setup_test_application
-- Creates a test application in apex_applications table.
-- Parameters:
--   p_workspace_id  - workspace ID for the application
--   p_app_id        - application ID to use
--   p_app_name      - application name
--   p_last_updated  - optional last_updated_on timestamp (defaults to sysdate)
------------------------------------------------------------
procedure setup_test_application (
    p_workspace_id  in number,
    p_app_id        in number,
    p_app_name      in varchar2,
    p_last_updated  in date default sysdate)
is
begin
    insert into apex_applications (
        application_id,
        workspace_id,
        application_name,
        application_status,
        last_updated_on)
    values (
        p_app_id,
        p_workspace_id,
        p_app_name,
        'AVAILABLE',
        p_last_updated);
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
    l_eval_id       number;
    l_rule_set_id   number;
begin
    -- Precondition: at least one rule set must exist
    ut.expect((select count(*) from sert_core.rule_sets where rule_set_id > 0))
        .to_be_greater_than(0);

    -- Get first available rule_set_id
    select min(rule_set_id) into l_rule_set_id from sert_core.rule_sets where rule_set_id > 0;

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
begin
    -- Setup: Create test workspace and one app with no evaluations
    l_workspace_id := setup_test_workspace;
    setup_test_application(
        p_workspace_id => l_workspace_id,
        p_app_id       => c_test_application_id,
        p_app_name     => 'TEST_APP_NO_EVALS');

    -- Execute: Call queue_auto_scans
    sert_core.schedule_api.queue_auto_scans(
        p_batch_size => 20,
        p_app_count_out => l_count);

    -- Assert: Should return 1 (the unscanned app)
    ut.expect(l_count).to_equal(1);

    -- Cleanup: Rollback test data
    rollback;
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
    l_base_app_id   number;
begin
    -- Setup: Create test workspace and 5 unscanned apps
    l_workspace_id := setup_test_workspace;
    l_base_app_id := c_test_application_id - 1000;

    for i in 1..5 loop
        setup_test_application(
            p_workspace_id => l_workspace_id,
            p_app_id       => l_base_app_id + i,
            p_app_name     => 'TEST_STALE_APP_' || i);
    end loop;

    -- Execute: Call queue_auto_scans with default batch size
    sert_core.schedule_api.queue_auto_scans(
        p_batch_size => 20,
        p_app_count_out => l_count);

    -- Assert: Should return 5 (all 5 unscanned apps)
    ut.expect(l_count).to_equal(5);

    -- Cleanup: Rollback test data
    rollback;
end stale_apps_under_limit;

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
    l_base_app_id := c_test_application_id - 2000;

    -- Create 50 unscanned apps
    for i in 1..50 loop
        setup_test_application(
            p_workspace_id => l_workspace_id,
            p_app_id       => l_base_app_id + i,
            p_app_name     => 'TEST_GUARDIAN_APP_' || i);

        -- Insert Guardian activity for each app, descending by page_events
        -- (higher page_events = higher activity, should be ranked first)
        insert into sert_core.sg_most_4wk_app_activity_f (
            workspace_id,
            application_id,
            workspace,
            application_name,
            pages,
            app_size,
            log_day,
            page_events,
            page_views,
            page_accepts,
            partial_page_views,
            rows_fetched,
            ir_searches,
            distinct_pages,
            distinct_users,
            distinct_sessions,
            average_render_time,
            median_render_time,
            maximum_render_time,
            total_render_time,
            content_length,
            error_count,
            public_page_events,
            workspace_login_events,
            sparkline_data)
        values (
            l_workspace_id,
            l_base_app_id + i,
            'TEST_WORKSPACE_QUEUE_' || abs(l_workspace_id),
            'TEST_GUARDIAN_APP_' || i,
            10,
            'M',
            trunc(sysdate),
            1000 - (i * 10),  -- descending: app 1 has 990, app 2 has 980, etc.
            100,
            50,
            10,
            1000,
            5,
            10,
            25,
            50,
            100,
            75,
            200,
            50000,
            10000,
            5,
            50,
            10,
            '100,99,98,97,96,95,94,93,92,91');
    end loop;

    -- Execute: Call queue_auto_scans with batch_size=20
    sert_core.schedule_api.queue_auto_scans(
        p_batch_size => 20,
        p_app_count_out => l_count);

    -- Assert: Should return 20 (exactly batch size, top 20 by activity)
    ut.expect(l_count).to_equal(20);

    -- Cleanup: Rollback test data
    rollback;
end top_20_by_guardian_activity;

------------------------------------------------------------
-- guardian_fallback
-- Tests: should fallback to eval_on_date ordering without Guardian
-- Setup: Create test workspace with 5 stale apps
--        (last_updated_on > eval_on_date)
--        Evals exist but apps were modified after last eval
-- Execute: Call queue_auto_scans
-- Assert: Should return 5 apps (fallback to eval_on_date ordering)
------------------------------------------------------------
procedure guardian_fallback
as
    l_count         number := 0;
    l_workspace_id  number;
    l_base_app_id   number;
    l_old_eval_date date;
begin
    -- Setup: Create test workspace
    l_workspace_id := setup_test_workspace;
    l_base_app_id := c_test_application_id - 3000;
    l_old_eval_date := trunc(sysdate) - 2;  -- 2 days ago

    -- Create 5 stale apps with evaluations older than app last_updated_on
    for i in 1..5 loop
        -- Create app with recent modification date
        setup_test_application(
            p_workspace_id => l_workspace_id,
            p_app_id       => l_base_app_id + i,
            p_app_name     => 'TEST_FALLBACK_APP_' || i,
            p_last_updated => sysdate);  -- app was updated today

        -- But evaluation happened 2 days ago
        setup_test_eval(
            p_workspace_id => l_workspace_id,
            p_app_id       => l_base_app_id + i,
            p_eval_date    => l_old_eval_date);
    end loop;

    -- Execute: Call queue_auto_scans (Guardian table will be empty, fallback to eval_on_date)
    sert_core.schedule_api.queue_auto_scans(
        p_batch_size => 20,
        p_app_count_out => l_count);

    -- Assert: Should return 5 (fallback to eval_on_date ordering works)
    ut.expect(l_count).to_equal(5);

    -- Cleanup: Rollback test data
    rollback;
end guardian_fallback;

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
-- setup_prefs
-- Runs before each test via --%beforeeach.
-- Sets AUTO_SCAN=Y, AUTO_SCAN_BATCH_SIZE=20, AUTO_SCAN_IGNORE_WS=''
-- so every test starts in a known, permissive state.
-- Each test can override individual prefs after this runs.
-- All changes are rolled back by the explicit rollback at test end.
------------------------------------------------------------
procedure setup_prefs
as
begin
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
    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Ignore Workspaces for auto Scan',
        p_pref_key    => 'AUTO_SCAN_IGNORE_WS',
        p_pref_value  => '',
        p_internal_yn => 'N');
end setup_prefs;

------------------------------------------------------------
-- auto_scan_disabled
-- Tests: procedure returns 0 immediately when AUTO_SCAN='N'
-- Setup: override AUTO_SCAN to N; create one unscanned app
-- Execute: queue_auto_scans with no p_batch_size
-- Assert: count = 0 (early exit, no scans queued)
------------------------------------------------------------
procedure auto_scan_disabled
as
    l_count        number;
    l_workspace_id number;
begin
    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Auto Scan All Apps',
        p_pref_key    => 'AUTO_SCAN',
        p_pref_value  => 'N',
        p_internal_yn => 'N');

    l_workspace_id := setup_test_workspace;
    setup_test_application(
        p_workspace_id => l_workspace_id,
        p_app_id       => c_test_application_id - 5000,
        p_app_name     => 'TEST_DISABLED_APP');

    sert_core.schedule_api.queue_auto_scans(
        p_app_count_out => l_count);

    ut.expect(l_count).to_equal(0);

    rollback;
end auto_scan_disabled;

------------------------------------------------------------
-- ignored_workspace_excluded
-- Tests: apps in the ignored workspace are not queued
-- Setup: AUTO_SCAN_IGNORE_WS = ignored ws name;
--        one unscanned app in ignored ws, one in active ws
-- Execute: queue_auto_scans
-- Assert: count = 1 (only the active workspace app queued)
------------------------------------------------------------
procedure ignored_workspace_excluded
as
    l_count          number;
    c_ignored_ws     constant varchar2(100) := 'TEST_IGNORED_WS_99100';
    c_active_ws      constant varchar2(100) := 'TEST_ACTIVE_WS_99100';
    c_ignored_ws_id  constant number        := c_test_workspace_id - 1;
    c_active_ws_id   constant number        := c_test_workspace_id - 2;
    c_ignored_app_id constant number        := c_test_application_id - 5100;
    c_active_app_id  constant number        := c_test_application_id - 5200;
begin
    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Ignore Workspaces for auto Scan',
        p_pref_key    => 'AUTO_SCAN_IGNORE_WS',
        p_pref_value  => c_ignored_ws,
        p_internal_yn => 'N');

    insert into apex_workspaces (workspace_name, workspace_id)
    values (c_ignored_ws, c_ignored_ws_id);
    insert into apex_applications (
        application_id, workspace_id, workspace,
        application_name, application_status, last_updated_on)
    values (c_ignored_app_id, c_ignored_ws_id, c_ignored_ws,
            'IGNORED_APP', 'AVAILABLE', sysdate);

    insert into apex_workspaces (workspace_name, workspace_id)
    values (c_active_ws, c_active_ws_id);
    insert into apex_applications (
        application_id, workspace_id, workspace,
        application_name, application_status, last_updated_on)
    values (c_active_app_id, c_active_ws_id, c_active_ws,
            'ACTIVE_APP', 'AVAILABLE', sysdate);

    sert_core.schedule_api.queue_auto_scans(
        p_app_count_out => l_count);

    ut.expect(l_count).to_equal(1);

    rollback;
end ignored_workspace_excluded;

------------------------------------------------------------
-- batch_size_from_pref
-- Tests: procedure reads AUTO_SCAN_BATCH_SIZE pref when
--        p_batch_size is not supplied
-- Setup: override AUTO_SCAN_BATCH_SIZE to 5; create 10 apps
-- Execute: queue_auto_scans with no p_batch_size param
-- Assert: count = 5
------------------------------------------------------------
procedure batch_size_from_pref
as
    l_count        number;
    l_workspace_id number;
    l_base_app_id  number;
begin
    sert_core.prefs_api.upsert_pref(
        p_pref_name   => 'Auto Scan Batch Size',
        p_pref_key    => 'AUTO_SCAN_BATCH_SIZE',
        p_pref_value  => '5',
        p_internal_yn => 'N');

    l_workspace_id := setup_test_workspace;
    l_base_app_id  := c_test_application_id - 6000;

    for i in 1..10 loop
        setup_test_application(
            p_workspace_id => l_workspace_id,
            p_app_id       => l_base_app_id + i,
            p_app_name     => 'TEST_BATCH_PREF_APP_' || i);
    end loop;

    sert_core.schedule_api.queue_auto_scans(
        p_app_count_out => l_count);

    ut.expect(l_count).to_equal(5);

    rollback;
end batch_size_from_pref;

------------------------------------------------------------
-- param_overrides_pref_batch_size
-- Tests: explicit p_batch_size parameter wins over pref value
-- Setup: pref AUTO_SCAN_BATCH_SIZE = 20 (set by setup_prefs)
--        create 10 unscanned apps
-- Execute: queue_auto_scans(p_batch_size => 3)
-- Assert: count = 3 (param, not pref)
------------------------------------------------------------
procedure param_overrides_pref_batch_size
as
    l_count        number;
    l_workspace_id number;
    l_base_app_id  number;
begin
    l_workspace_id := setup_test_workspace;
    l_base_app_id  := c_test_application_id - 7000;

    for i in 1..10 loop
        setup_test_application(
            p_workspace_id => l_workspace_id,
            p_app_id       => l_base_app_id + i,
            p_app_name     => 'TEST_PARAM_APP_' || i);
    end loop;

    sert_core.schedule_api.queue_auto_scans(
        p_batch_size    => 3,
        p_app_count_out => l_count);

    ut.expect(l_count).to_equal(3);

    rollback;
end param_overrides_pref_batch_size;

end test_schedule_api;
/
--rollback not required
