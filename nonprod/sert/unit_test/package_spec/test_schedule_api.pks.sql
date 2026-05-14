--liquibase formatted sql
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown
-- at https://oss.oracle.com/licenses/upl/
--------------------------------------------------------------------------------

--changeset mipotter:create_spec_unit_test.test_schedule_api_1777984399 stripComments:false endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create or replace package unit_test.test_schedule_api
as
-- Pref snapshot collection for Option 3 state restoration.
-- Uses prefs_api.t_pref_rec; a null pref_key means the row did not exist.
type t_pref_snap_tab is table of sert_core.prefs_api.t_pref_rec index by pls_integer;

   --%suite(schedule_api.queue_auto_scans)
   --%suitepath(sert_core)

   --%beforeeach
   procedure setup_prefs;
   ------------------------------------------------------------
   -- restore_prefs
   -- Restores the three prefs that setup_prefs overwrote.
   -- Uses prefs_api.upsert_pref to restore rows that existed.
   -- Commits after restore since it is called in tests where
   -- queue_auto_scans has already issued an implicit commit.
   ------------------------------------------------------------
   --%aftereach
   --%rollback(manual)
   procedure restore_prefs;

   --%test(should_return_0_when_no_stale_or_unscanned_apps)
   --%rollback(manual)
   procedure no_stale_apps;

   --%test(should_queue_all_stale_apps_when_less_than_20)
   --%rollback(manual)
   procedure stale_apps_under_limit;

   --%test(should_exclude_apps_in_ignored_workspace)
   --%rollback(manual)
   procedure ignored_workspace_excluded;
/*
   --%test(should_queue_top_20_ranked_by_guardian_activity)
   procedure top_20_by_guardian_activity;

   --%test(should_fallback_to_eval_date_without_guardian)
   procedure guardian_fallback;

   --%test(should_continue_on_eval_failure_and_return_queued_count)
   procedure error_handling;

   --%test(should_return_0_when_auto_scan_pref_is_N)
   --%rollback(manual)
   procedure auto_scan_disabled;


   --%test(should_queue_batch_size_from_pref_when_no_param_supplied)
   --%rollback(manual)
   procedure batch_size_from_pref;

   --%test(should_use_explicit_param_batch_size_over_pref)
   --%rollback(manual)
   procedure param_overrides_pref_batch_size;

   --%test(should_not_queue_app_evaluated_within_1_day_of_modification)
   --%rollback(manual)
   procedure recently_evaluated_not_stale;

   --%test(should_create_sert_auto_scan_job_with_default_hourly_interval)
   --%rollback(manual)
   procedure setup_auto_scan_job_defaults;

   --%test(should_create_job_with_minutely_frequency_and_custom_interval)
   --%rollback(manual)
   procedure setup_auto_scan_job_minutely;

   --%test(should_default_invalid_frequency_to_hourly)
   --%rollback(manual)
   procedure setup_auto_scan_job_invalid_freq;

   --%test(should_default_out_of_range_interval_to_1)
   --%rollback(manual)
   procedure setup_auto_scan_job_invalid_interval;

   --%test(should_replace_existing_job_settings_on_second_call)
   --%rollback(manual)
   procedure setup_auto_scan_job_idempotent;
*/
end test_schedule_api;
/
--rollback not required
