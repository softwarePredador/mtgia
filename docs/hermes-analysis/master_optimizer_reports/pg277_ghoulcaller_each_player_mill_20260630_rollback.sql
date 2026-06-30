BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ghoulcaller''s bell')
   OR normalized_name LIKE 'ghoulcaller''s bell // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg277_ghoulcaller_each_player_mill_20260630_114747;

COMMIT;
