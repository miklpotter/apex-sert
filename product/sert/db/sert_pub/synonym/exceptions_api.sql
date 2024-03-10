--liquibase formatted sql

--changeset mipotter:create_synonym_sert_pub_exceptions_api endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create synonym ${sert_pub_schema}.exceptions_api for ${sert_core_schema}.exceptions_api
/
--rollback not required