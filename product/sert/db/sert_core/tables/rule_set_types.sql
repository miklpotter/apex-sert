--liquibase formatted sql

--changeset mipotter:create_table_sert_core.rule_set_types endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_tables  where owner = upper('${sert_core_schema}') and table_name = 'RULE_SET_TYPES';
CREATE TABLE  ${sert_core_schema}.rule_set_types (
    rule_set_type_id   NUMBER
        GENERATED BY DEFAULT AS IDENTITY ( START WITH 1 NOCACHE ORDER )
    NOT NULL,
    rule_set_type_name VARCHAR2(250) NOT NULL,
    rule_set_type_key  VARCHAR2(250) NOT NULL,
    description        VARCHAR2(4000),
    created_by         VARCHAR2(250) DEFAULT ON NULL coalesce(sys_context('APEX$SESSION', 'APP_USER'),
                                                      user) NOT NULL,
    created_on         TIMESTAMP WITH LOCAL TIME ZONE DEFAULT ON NULL systimestamp NOT NULL,
    updated_by         VARCHAR2(250) DEFAULT ON NULL coalesce(sys_context('APEX$SESSION', 'APP_USER'),
                                                      user),
    updated_on         TIMESTAMP WITH LOCAL TIME ZONE DEFAULT ON NULL systimestamp
)
LOGGING;

ALTER TABLE  ${sert_core_schema}.rule_set_types ADD CONSTRAINT rule_set_types_pk PRIMARY KEY ( rule_set_type_id );

ALTER TABLE  ${sert_core_schema}.rule_set_types ADD CONSTRAINT rule_set_types_un UNIQUE ( rule_set_type_key );
--rollback drop table ${sert_core_schema}.rule_set_types;