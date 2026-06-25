BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('utvara hellkite')
   OR normalized_name LIKE 'utvara hellkite // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg210_utvara_hellkite_20260625_081209;

COMMIT;
