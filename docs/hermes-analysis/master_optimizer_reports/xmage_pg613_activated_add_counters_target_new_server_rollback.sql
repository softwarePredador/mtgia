BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dragon blood', 'fevered convulsions', 'gnarled effigy')
   OR normalized_name LIKE 'dragon blood // %'
   OR normalized_name LIKE 'fevered convulsions // %'
   OR normalized_name LIKE 'gnarled effigy // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg613_activated_add_counters_target_new_20260707_120118;

COMMIT;
