--liquibase formatted sql

--changeset mipotter:create_view_sert_pub.comments_pub_v_1710066969861 endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create or replace view ${sert_pub_schema}.comments_pub_v
as
select
   c.comment_id
  ,c.comments
  ,c.rule_set_id
  ,c.rule_id
  ,c.workspace_id
  ,c.application_id
  ,c.page_id
  ,c.component_id
  ,c.column_name
  ,c.shared_comp_name
  ,c.item_name
  ,c.created_on
  ,c.created_by
  ,c.updated_on
  ,c.updated_by
from
  ${sert_core_schema}.comments_pub_v c
/
--rollback not required