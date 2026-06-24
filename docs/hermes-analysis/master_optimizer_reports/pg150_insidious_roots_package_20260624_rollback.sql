BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('insidious roots')
   OR normalized_name LIKE 'insidious roots // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg150_insidious_roots_20260624_071922;

COMMIT;
