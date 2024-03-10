--liquibase formatted sql

--changeset mipotter:create_package_spec_sert_core.sert_core endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create or replace package ${sert_core_schema}.rules_pkg
as

procedure import
  (
   p_name in varchar2
  );

procedure export;

procedure add_rule_to_rule_set
  (
   p_rule_id in number
  ,p_rule_sets in varchar2
  );

procedure copy_rule
  (
   p_rule_id   in out number
  ,p_rule_name in varchar2
  ,p_rule_key  in varchar2
  ,p_rule_sets in varchar2 default null
  );

end rules_pkg;
/
--rollback not required