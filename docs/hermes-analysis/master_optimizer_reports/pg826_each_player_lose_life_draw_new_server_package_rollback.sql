BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('crushing disappointment', 'risky shortcut')
   OR normalized_name LIKE 'crushing disappointment // %'
   OR normalized_name LIKE 'risky shortcut // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg826_pg826_each_player_lose_life_draw_n_20260712_104644;

COMMIT;
