--liquibase formatted sql

--changeset mipotter:grant_execute_on_sert_core_eval_pkg endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
grant execute on ${sert_core_schema}.eval_pkg to ${sert_pub_schema}
/
--rollback not required