BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('control of the court', 'goblin lore')
   OR normalized_name LIKE 'control of the court // %'
   OR normalized_name LIKE 'goblin lore // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg714_random_draw_discard_new_server_20260710_183757;

COMMIT;
