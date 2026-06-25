BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('taii wakeen, perfect shot')
   OR normalized_name LIKE 'taii wakeen, perfect shot // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg199_taii_wakeen_20260625_022333;

COMMIT;
