BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('perpetual timepiece')
   OR normalized_name LIKE 'perpetual timepiece // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg274_perpetual_timepiece_graveyard_shuffle_20260630;

COMMIT;
