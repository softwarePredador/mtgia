BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('goliath daydreamer')
   OR normalized_name LIKE 'goliath daydreamer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg246_goliath_daydreamer_free_cast_20260628_105607;

COMMIT;
