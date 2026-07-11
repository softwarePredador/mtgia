BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('zaxara, the exemplary')
   OR normalized_name LIKE 'zaxara, the exemplary // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg766_zaxara_new_server_zaxara_x_spell_h_20260711_140715;

COMMIT;
