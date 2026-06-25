BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('surly badgersaur')
   OR normalized_name LIKE 'surly badgersaur // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg198_surly_badgersaur_20260625_015702;

COMMIT;
