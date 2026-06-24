BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('kindle the inner flame')
   OR normalized_name LIKE 'kindle the inner flame // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg148_kindle_inner_flame_20260624_064011;

COMMIT;
