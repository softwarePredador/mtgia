BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('clever concealment')
   OR normalized_name LIKE 'clever concealment // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg205_phase_out_protection_20260625_061320;

COMMIT;
