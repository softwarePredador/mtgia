BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('mana leak', 'miscast', 'spell pierce')
   OR normalized_name LIKE 'mana leak // %'
   OR normalized_name LIKE 'miscast // %'
   OR normalized_name LIKE 'spell pierce // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg155_soft_counters_20260624_082943;

COMMIT;
