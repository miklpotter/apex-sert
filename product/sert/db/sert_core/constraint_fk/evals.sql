--liquibase formatted sql

--changeset mipotter:alter_table_sert_core.evals_add_constraint_e_rule_sets_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'E_RULE_SETS_FK';
ALTER TABLE ${sert_core_schema}.evals
    ADD CONSTRAINT e_rule_sets_fk FOREIGN KEY ( rule_set_id )
        REFERENCES rule_sets ( rule_set_id )
    NOT DEFERRABLE;
--rollback alter table drop constraint e_rule_sets_fk;