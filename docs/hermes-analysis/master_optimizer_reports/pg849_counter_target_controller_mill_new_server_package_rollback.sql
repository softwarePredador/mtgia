BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('countermand', 'didn''t say please', 'psychic strike', 'thought collapse')
   OR normalized_name LIKE 'countermand // %'
   OR normalized_name LIKE 'didn''t say please // %'
   OR normalized_name LIKE 'psychic strike // %'
   OR normalized_name LIKE 'thought collapse // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg849_counter_target_controller_mill_new_20260712_224816;

COMMIT;
