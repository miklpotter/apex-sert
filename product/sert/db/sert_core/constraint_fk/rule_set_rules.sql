--liquibase formatted sql

--changeset mipotter:alter_table_sert_core.rule_set_rules_add_constraint_rule_set_rules_rule_sets_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'RULE_SET_RULES_RULE_SETS_FK';
ALTER TABLE ${sert_core_schema}.rule_set_rules
    ADD CONSTRAINT rule_set_rules_rule_sets_fk FOREIGN KEY ( rule_set_id )
        REFERENCES rule_sets ( rule_set_id )
            ON DELETE CASCADE
    NOT DEFERRABLE;
--rollback alter table drop constraint rule_set_rules_rule_sets_fk;

--changeset mipotter:alter_table_sert_core.rule_set_rules_add_constraint_rule_set_rules_rules_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'RULE_SET_RULES_RULES_FK';
ALTER TABLE ${sert_core_schema}.rule_set_rules
    ADD CONSTRAINT rule_set_rules_rules_fk FOREIGN KEY ( rule_id )
        REFERENCES rules ( rule_id )
            ON DELETE CASCADE
    NOT DEFERRABLE;
--rollback alter table drop constraint rule_set_rules_rules_fk;