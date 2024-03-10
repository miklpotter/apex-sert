--liquibase formatted sql

--changeset mipotter:alter_table_sert_core.rules_add_constraint_r_categories_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'R_CATEGORIES_FK';
ALTER TABLE ${sert_core_schema}.rules
    ADD CONSTRAINT r_categories_fk FOREIGN KEY ( category_id )
        REFERENCES categories ( category_id )
            ON DELETE CASCADE
    NOT DEFERRABLE;
--rollback alter table drop constraint r_categories_fk;

--changeset mipotter:alter_table_sert_core.rules_add_constraint_r_risks_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'R_RISKS_FK';
ALTER TABLE ${sert_core_schema}.rules
    ADD CONSTRAINT r_risks_fk FOREIGN KEY ( risk_id )
        REFERENCES risks ( risk_id )
    NOT DEFERRABLE;
--rollback alter table drop constraint r_risks_fk;

--changeset mipotter:alter_table_sert_core.rules_add_constraint_r_rule_criteria_type_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'R_RULE_CRITERIA_TYPE_FK';
ALTER TABLE ${sert_core_schema}.rules
    ADD CONSTRAINT r_rule_criteria_type_fk FOREIGN KEY ( rule_criteria_type_id )
        REFERENCES rule_criteria_types ( rule_criteria_type_id )
    NOT DEFERRABLE;
--rollback alter table drop constraint r_rule_criteria_type_fk;

--changeset mipotter:alter_table_sert_core.rules_add_constraint_r_rule_severity_fk endDelimiter:; runOnChange:true runAlways:false rollbackEndDelimiter:;
--preconditions onFail:MARK_RAN onError:HALT
--precondition-sql-check expectedResult:0 select count(1) from all_constraints where owner = 'SERT_CORE' and constraint_name = 'R_RULE_SEVERITY_FK';
ALTER TABLE ${sert_core_schema}.rules
    ADD CONSTRAINT r_rule_severity_fk FOREIGN KEY ( rule_severity_id )
        REFERENCES rule_severity ( rule_severity_id )
    NOT DEFERRABLE;
--rollback alter table drop constraint r_rule_severity_fk;