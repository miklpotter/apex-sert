--liquibase formatted sql

--changeset mipotter:create_synonym_sert_pub_comments_api endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create synonym ${sert_pub_schema}.comments_api for ${sert_core_schema}.comments_api
/
--rollback not required