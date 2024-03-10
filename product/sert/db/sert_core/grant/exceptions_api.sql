--liquibase formatted sql

--changeset mipotter:grant_execute_on_sert_core_exceptions_api endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
grant execute on ${sert_core_schema}.exceptions_api to ${sert_pub_schema}
/
--rollback not required