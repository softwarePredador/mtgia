BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('birthing boughs')
   OR normalized_name LIKE 'birthing boughs // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg861_token_static_identity_new_server_20260713_035756;

COMMIT;
