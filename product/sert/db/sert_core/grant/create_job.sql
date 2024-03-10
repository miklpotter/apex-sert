--liquibase formatted sql

--changeset mipotter:grant_create_job_to_sert_core endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
grant create job to ${sert_core_schema}
/
--rollback not required