--liquibase formatted sql

--changeset mipotter:grant_execute_on_dbms_scheduler_to_sert_core endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
grant execute on dbms_scheduler to ${sert_core_schema}
/
--rollback not required