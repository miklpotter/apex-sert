--liquibase formatted sql
-------------------------------------------------------------------------------
-- Copyright (c) 2024 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown
-- at https://oss.oracle.com/licenses/upl/
--------------------------------------------------------------------------------

--changeset mipotter:create_spec_unit_test.test_schedule_api_1777984399 stripComments:false endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create or replace package unit_test.test_schedule_api
as

   --%suite(schedule_api.queue_auto_scans)
   --%suitepath(sert_core)

   --%test(should_return_0_when_no_stale_or_unscanned_apps)
   procedure no_stale_apps;

   --%test(should_queue_all_stale_apps_when_less_than_20)
   procedure stale_apps_under_limit;

   --%test(should_queue_top_20_ranked_by_guardian_activity)
   procedure top_20_by_guardian_activity;

   --%test(should_fallback_to_eval_date_without_guardian)
   procedure guardian_fallback;

   --%test(should_continue_on_eval_failure_and_return_queued_count)
   procedure error_handling;

end test_schedule_api;
/
--rollback not required
