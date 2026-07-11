BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('kozilek''s translator')
   OR normalized_name LIKE 'kozilek''s translator // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg744_limited_pay_life_mana_source_new_s_20260711_061612;

COMMIT;
