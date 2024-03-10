--liquibase formatted sql

--changeset mipotter:create_trigger_sert_core.triggers endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_CATEGORIES
    BEFORE UPDATE ON CATEGORIES
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_comments endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_COMMENTS
    BEFORE UPDATE ON COMMENTS
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_eval_results endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_EVAL_RESULTS
    BEFORE UPDATE ON EVAL_RESULTS
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required


--changeset mipotter:create_trigger_sert_core.bu_evals endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_EVALS
    BEFORE UPDATE ON EVALS
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required

--changeset mipotter:create_trigger_sert_core.bu_exceptions endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_EXCEPTIONS
    BEFORE UPDATE ON EXCEPTIONS
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required

--changeset mipotter:create_trigger_sert_core.bu_prefs endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_PREFS
    BEFORE UPDATE ON PREFS
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_reserved_strings endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_RESERVED_STRINGS
    BEFORE UPDATE ON RESERVED_STRINGS
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_risks endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_RISKS
    BEFORE UPDATE ON RISKS
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_rule_criteria endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_RULE_CRITERIA
    BEFORE UPDATE ON RULE_CRITERIA
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_rule_criteria_types endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_RULE_CRITERIA_TYPES
    BEFORE UPDATE ON RULE_CRITERIA_TYPES
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_rule_set_rules endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_RULE_SET_RULES
    BEFORE UPDATE ON RULE_SET_RULES
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_rule_set_types endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_RULE_SET_TYPES
    BEFORE UPDATE ON RULE_SET_TYPES
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_rule_sets endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_RULE_SETS
    BEFORE UPDATE ON RULE_SETS
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_rule_severity endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_RULE_SEVERITY
    BEFORE UPDATE ON RULE_SEVERITY
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_rules endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_RULES
    BEFORE UPDATE ON RULES
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required
--changeset mipotter:create_trigger_sert_core.bu_shared_comp_views endDelimiter:/ runOnChange:true runAlways:false rollbackEndDelimiter:/
CREATE OR REPLACE TRIGGER sert_core.BU_SHARED_COMP_VIEWS
    BEFORE UPDATE ON SHARED_COMP_VIEWS
    FOR EACH ROW
begin
:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
:new.updated_on := systimestamp;
end;
/
--rollback not required