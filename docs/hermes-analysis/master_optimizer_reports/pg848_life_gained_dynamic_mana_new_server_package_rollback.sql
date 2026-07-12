BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('accomplished alchemist')
   OR normalized_name LIKE 'accomplished alchemist // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg848_life_gained_dynamic_mana_new_serve_20260712_222154;

COMMIT;
