BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('glint-horn buccaneer')
   OR normalized_name LIKE 'glint-horn buccaneer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg194_glint_horn_buccaneer_20260624_234925;

COMMIT;
