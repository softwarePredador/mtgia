BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('free from flesh', 'fully grown', 'heightened reflexes', 'spontaneous flight')
   OR normalized_name LIKE 'free from flesh // %'
   OR normalized_name LIKE 'fully grown // %'
   OR normalized_name LIKE 'heightened reflexes // %'
   OR normalized_name LIKE 'spontaneous flight // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg833_boost_add_counter_target_new_serve_20260712_132401;

COMMIT;
