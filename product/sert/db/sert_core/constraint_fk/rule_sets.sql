--liquibase formatted sql

--changeset mipotter:alter_table_sert_core.rule_sets_add_constraint_rs_rule_set_types_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'RS_RULE_SET_TYPES_FK';
ALTER TABLE ${sert_core_schema}.rule_sets
    ADD CONSTRAINT rs_rule_set_types_fk FOREIGN KEY ( rule_set_type_id )
        REFERENCES rule_set_types ( rule_set_type_id )
    NOT DEFERRABLE;
--rollback alter table drop constraint rs_rule_set_types_fk;