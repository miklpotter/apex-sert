--liquibase formatted sql

--changeset mipotter:create_table_sert_core.exceptions endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_tables  where owner = upper('${sert_core_schema}') and table_name = 'EXCEPTIONS';
CREATE TABLE  ${sert_core_schema}.exceptions (
    exception_id     NUMBER
        GENERATED BY DEFAULT AS IDENTITY ( START WITH 1 NOCACHE ORDER )
    NOT NULL,
    rule_set_id      NUMBER NOT NULL,
    rule_id          NUMBER NOT NULL,
    exception        VARCHAR2(4000) NOT NULL,
    workspace_id     NUMBER NOT NULL,
    application_id   NUMBER NOT NULL,
    page_id          NUMBER,
    component_id     VARCHAR2(250),
    column_name      VARCHAR2(250),
    item_name        VARCHAR2(250),
    shared_comp_name VARCHAR2(250),
    result           VARCHAR2(250) NOT NULL,
    reason           VARCHAR2(4000),
    current_value    VARCHAR2(4000),
    created_by       VARCHAR2(250) DEFAULT ON NULL coalesce(sys_context('APEX$SESSION', 'APP_USER'),
                                                      user) NOT NULL,
    created_on       TIMESTAMP WITH LOCAL TIME ZONE DEFAULT ON NULL systimestamp NOT NULL,
    updated_by       VARCHAR2(250) DEFAULT ON NULL coalesce(sys_context('APEX$SESSION', 'APP_USER'),
                                                      user),
    updated_on       TIMESTAMP WITH LOCAL TIME ZONE DEFAULT ON NULL systimestamp,
    actioned_by      VARCHAR2(250),
    actioned_on      TIMESTAMP WITH LOCAL TIME ZONE
)
LOGGING;

ALTER TABLE  ${sert_core_schema}.exceptions ADD CONSTRAINT exceptions_pk PRIMARY KEY ( exception_id );
--rollback drop table ${sert_core_schema}.exceptions;