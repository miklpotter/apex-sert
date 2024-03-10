--liquibase formatted sql

--changeset mipotter:create_package_spec_sert_core.sert_core endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
create or replace package ${sert_core_schema}.log_pkg
as

function get_log_key
return varchar2;

procedure log
  (
   p_log      in varchar2 default null
  ,p_log_type in varchar2 default 'GENERIC'
  ,p_log_key  in varchar2 default null
  ,p_log_clob in varchar2 default null
  ,p_id       in varchar2 default null
  ,p_id_col   in varchar2 default null
  );

function error
  (
  p_error in apex_error.t_error
  )
return apex_error.t_error_result;

end log_pkg;
/
--rollback not required