--liquibase formatted sql

--changeset mipotter:alter_table_sert_core.eval_results_add_constraint_er_evals_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'ER_EVALS_FK';
ALTER TABLE ${sert_core_schema}.eval_results
    ADD CONSTRAINT er_evals_fk FOREIGN KEY ( eval_id )
        REFERENCES evals ( eval_id )
            ON DELETE CASCADE
    NOT DEFERRABLE;
--rollback alter table drop constraint er_evals_fk;

--changeset mipotter:alter_table_sert_core.eval_results_add_constraint_er_rules_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'ER_RULES_FK';
ALTER TABLE ${sert_core_schema}.eval_results
    ADD CONSTRAINT er_rules_fk FOREIGN KEY ( rule_id )
        REFERENCES rules ( rule_id )
    NOT DEFERRABLE;
--rollback alter table drop constraint er_rules_fk;