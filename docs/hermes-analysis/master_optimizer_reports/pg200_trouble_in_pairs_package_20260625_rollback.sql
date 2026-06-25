BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('trouble in pairs')
   OR normalized_name LIKE 'trouble in pairs // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg200_trouble_in_pairs_20260625_025547;

COMMIT;
