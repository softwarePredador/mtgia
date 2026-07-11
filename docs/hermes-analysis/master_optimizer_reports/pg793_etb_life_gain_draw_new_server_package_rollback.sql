BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cloudblazer', 'elite guardmage', 'inspiring overseer', 'priest of ancient lore')
   OR normalized_name LIKE 'cloudblazer // %'
   OR normalized_name LIKE 'elite guardmage // %'
   OR normalized_name LIKE 'inspiring overseer // %'
   OR normalized_name LIKE 'priest of ancient lore // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg793_etb_life_gain_draw_new_server_20260711_232612;

COMMIT;
