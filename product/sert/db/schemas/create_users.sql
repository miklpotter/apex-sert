--liquibase formatted sql

--changeset mipotter:create_sert_core_schema endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_users where username = '${sert_core_schema}';
create user ${sert_core_schema} no authentication;
--rollback not required

-- create user ${sert_api_schema} no authentication;
--changeset mipotter:create_sert_pub_schema endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_users where username = '${sert_pub_schema}';
create user ${sert_pub_schema} no authentication;
--rollback not required

--changeset mipotter:create_sert_rest_schema endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_users where username = '${sert_rest_schema}';
create user ${sert_rest_schema} no authentication;
--rollback not required

--changeset mipotter:alter_user_sert_core_schema endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
alter user ${sert_core_schema}
default tablespace ${sert_data_tablespace} quota unlimited on ${sert_data_tablespace}
temporary tablespace ${sert_temp_tablespace};
--rollback not required

--changeset mipotter:alter_user_sert_pub_schema endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
alter user ${sert_pub_schema}
default tablespace ${sert_data_tablespace} quota unlimited on ${sert_data_tablespace}
temporary tablespace ${sert_temp_tablespace};
--rollback not required

--changeset mipotter:alter_user_sert_rest_schema endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
alter user ${sert_rest_schema}
default tablespace ${sert_data_tablespace} quota unlimited on ${sert_data_tablespace}
temporary tablespace ${sert_temp_tablespace};
--rollback not required
