--liquibase formatted sql

--changeset mipotter:grant_select_on_sert_core_eval_results_pub_v endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
grant select on ${sert_core_schema}.eval_results_pub_v to ${sert_pub_schema}
/
--rollback not required