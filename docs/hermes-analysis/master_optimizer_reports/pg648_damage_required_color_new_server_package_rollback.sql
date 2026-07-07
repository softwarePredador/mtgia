BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('evaporate')
   OR normalized_name LIKE 'evaporate // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg648_damage_required_color_new_server_20260707_231744;

COMMIT;
