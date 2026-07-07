BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('clash of wills', 'concerted defense', 'evasive action', 'ixidor''s will', 'spell stutter', 'syncopate', 'thassa''s rebuff')
   OR normalized_name LIKE 'clash of wills // %'
   OR normalized_name LIKE 'concerted defense // %'
   OR normalized_name LIKE 'evasive action // %'
   OR normalized_name LIKE 'ixidor''s will // %'
   OR normalized_name LIKE 'spell stutter // %'
   OR normalized_name LIKE 'syncopate // %'
   OR normalized_name LIKE 'thassa''s rebuff // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg598_dynamic_counter_unless_new_server_20260707_063333;

COMMIT;
