BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('baleful force', 'phyrexian arena')
   OR normalized_name LIKE 'baleful force // %'
   OR normalized_name LIKE 'phyrexian arena // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg844_beginning_upkeep_draw_lose_life_ne_20260712_205128;

COMMIT;
