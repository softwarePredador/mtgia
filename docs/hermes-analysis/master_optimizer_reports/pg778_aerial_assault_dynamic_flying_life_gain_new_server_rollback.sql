BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aerial assault')
   OR normalized_name LIKE 'aerial assault // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg778_aerial_assault_dynamic_flying_life_20260711_174857;

COMMIT;
