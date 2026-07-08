BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('calamitous cave-in', 'chain reaction', 'gates ablaze', 'immolating gyre', 'skyreaping')
   OR normalized_name LIKE 'calamitous cave-in // %'
   OR normalized_name LIKE 'chain reaction // %'
   OR normalized_name LIKE 'gates ablaze // %'
   OR normalized_name LIKE 'immolating gyre // %'
   OR normalized_name LIKE 'skyreaping // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg654_dynamic_damage_wipe_new_server_20260708_115133;

COMMIT;
