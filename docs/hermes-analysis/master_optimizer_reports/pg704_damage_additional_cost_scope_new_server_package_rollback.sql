BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('devour in flames', 'final flare', 'heartfire')
   OR normalized_name LIKE 'devour in flames // %'
   OR normalized_name LIKE 'final flare // %'
   OR normalized_name LIKE 'heartfire // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg704_damage_additional_cost_scope_new_s_20260710_142937;

COMMIT;
