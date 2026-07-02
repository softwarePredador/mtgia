BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('raise the past')
   OR normalized_name LIKE 'raise the past // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg367_return_all_graveyard_battlefield_wave_20260702_092;

COMMIT;
