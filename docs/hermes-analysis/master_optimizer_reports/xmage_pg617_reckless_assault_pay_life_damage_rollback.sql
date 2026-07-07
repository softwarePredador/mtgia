BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('reckless assault')
   OR normalized_name LIKE 'reckless assault // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg617_reckless_assault_pay_life_damage_p_20260707_131724;

COMMIT;
