BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('soul immolation')
   OR normalized_name LIKE 'soul immolation // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg213_soul_immolation_20260625_092521;

COMMIT;
