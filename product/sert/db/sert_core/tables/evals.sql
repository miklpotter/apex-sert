--liquibase formatted sql

--changeset mipotter:create_table_sert_core.evals endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_tables  where owner = upper('${sert_core_schema}') and table_name = 'EVALS';
CREATE TABLE  ${sert_core_schema}.evals (
    eval_id        NUMBER
        GENERATED BY DEFAULT AS IDENTITY ( START WITH 1 NOCACHE ORDER )
    NOT NULL,
    workspace_id   NUMBER NOT NULL,
    application_id NUMBER NOT NULL,
    rule_set_id    NUMBER NOT NULL,
    eval_on        TIMESTAMP WITH LOCAL TIME ZONE,
    eval_on_date   DATE NOT NULL,
    eval_by        VARCHAR2(250),
    summary        CLOB,
    job_name       VARCHAR2(250),
    job_status     VARCHAR2(250),
    score          NUMBER,
    created_by     VARCHAR2(250) DEFAULT ON NULL coalesce(sys_context('APEX$SESSION', 'APP_USER'),
                                                      user) NOT NULL,
    created_on     TIMESTAMP WITH LOCAL TIME ZONE DEFAULT ON NULL systimestamp NOT NULL,
    updated_by     VARCHAR2(250) DEFAULT ON NULL coalesce(sys_context('APEX$SESSION', 'APP_USER'),
                                                      user),
    updated_on     TIMESTAMP WITH LOCAL TIME ZONE DEFAULT ON NULL systimestamp
)
LOGGING;

ALTER TABLE  ${sert_core_schema}.evals ADD CONSTRAINT evals_pk PRIMARY KEY ( eval_id );
--rollback drop table ${sert_core_schema}.evals;