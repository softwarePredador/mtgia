BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('acolyte of affliction', 'corpse churn', 'eccentric farmer', 'grapple with the past', 'pothole mole')
   OR normalized_name LIKE 'acolyte of affliction // %'
   OR normalized_name LIKE 'corpse churn // %'
   OR normalized_name LIKE 'eccentric farmer // %'
   OR normalized_name LIKE 'grapple with the past // %'
   OR normalized_name LIKE 'pothole mole // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg343_xmage_recursion_mill_return_wave_20260702_012603;

COMMIT;
