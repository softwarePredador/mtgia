BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aftershock', 'infernal grasp', 'reckless spite', 'wicked pact', 'withering torment')
   OR normalized_name LIKE 'aftershock // %'
   OR normalized_name LIKE 'infernal grasp // %'
   OR normalized_name LIKE 'reckless spite // %'
   OR normalized_name LIKE 'wicked pact // %'
   OR normalized_name LIKE 'withering torment // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg682_destroy_source_controller_penalty_20260709_012940;

COMMIT;
