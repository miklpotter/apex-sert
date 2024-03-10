--liquibase formatted sql

--changeset mipotter:create_synonym_sert_pub_eval_pkg endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create synonym ${sert_pub_schema}.eval_pkg for ${sert_core_schema}.eval_pkg
/
--rollback not required