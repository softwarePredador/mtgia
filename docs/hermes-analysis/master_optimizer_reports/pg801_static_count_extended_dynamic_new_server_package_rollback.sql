BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('abomination of llanowar', 'ancient ooze', 'awakened amalgam', 'primalcrux', 'soulless one', 'umbra stalker')
   OR normalized_name LIKE 'abomination of llanowar // %'
   OR normalized_name LIKE 'ancient ooze // %'
   OR normalized_name LIKE 'awakened amalgam // %'
   OR normalized_name LIKE 'primalcrux // %'
   OR normalized_name LIKE 'soulless one // %'
   OR normalized_name LIKE 'umbra stalker // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg801_static_count_extended_dynamic_new_20260712_022103;

COMMIT;
