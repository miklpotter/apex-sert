create or replace package sert_core.rules_pkg
as

procedure import
  (
  p_name in varchar2
  );

procedure export;

end rules_pkg;
/