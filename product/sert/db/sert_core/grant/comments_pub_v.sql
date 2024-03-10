--liquibase formatted sql

--changeset mipotter:grant_select_on_sert_core_comments_pub_v endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
grant select on ${sert_core_schema}.comments_pub_v to ${sert_pub_schema}
/
--rollback not required