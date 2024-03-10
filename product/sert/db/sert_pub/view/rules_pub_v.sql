--liquibase formatted sql

--changeset mipotter:create_view_sert_pub.rules_pub_v_1710067011796 endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create or replace view ${sert_pub_schema}.rules_pub_v
as
select
   rule_id
  ,rule_name
  ,category_name
  ,category_key
  ,risk_name
  ,risk
  ,risk_url
  ,impact
  ,shared_comp_type
  ,rule_criteria_type_name
  ,info
  ,fix
  ,help_url
  ,builder_url
from
  ${sert_core_schema}.rules_pub_v
/
--rollback not required