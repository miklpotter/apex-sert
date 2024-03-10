--liquibase formatted sql

--changeset mipotter:alter_table_sert_core.rule_criteria_add_constraint_rc_rule_criteria_types_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'RC_RULE_CRITERIA_TYPES_FK';
ALTER TABLE ${sert_core_schema}.rule_criteria
    ADD CONSTRAINT rc_rule_criteria_types_fk FOREIGN KEY ( rule_criteria_type_id )
        REFERENCES rule_criteria_types ( rule_criteria_type_id )
    NOT DEFERRABLE;
--rollback alter table drop constraint rc_rule_criteria_types_fk;