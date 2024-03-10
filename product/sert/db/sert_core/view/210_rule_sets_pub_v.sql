--liquibase formatted sql

--changeset mipotter:create_view_sert_core.rule_sets_pub_v endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create or replace view ${sert_core_schema}.rule_sets_pub_v
as
select
   rule_set_id
  ,rule_set_type_id
  ,rule_set_type_name
  ,rule_set_type_key
  ,rule_set_name
  ,rule_set_key
  ,apex_version
  ,description
  ,cnt
from
  rule_sets_v
where
  active_yn = 'Y'
/
--rollback not required