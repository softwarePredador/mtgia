BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('courage in crisis', 'grim affliction')
   OR normalized_name LIKE 'courage in crisis // %'
   OR normalized_name LIKE 'grim affliction // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg834_add_counters_proliferate_new_serve_20260712_171340;

COMMIT;
