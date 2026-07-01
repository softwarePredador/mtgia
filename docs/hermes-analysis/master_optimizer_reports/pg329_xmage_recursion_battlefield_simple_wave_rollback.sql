BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ashen powder', 'helping hand', 'hymn of rebirth')
   OR normalized_name LIKE 'ashen powder // %'
   OR normalized_name LIKE 'helping hand // %'
   OR normalized_name LIKE 'hymn of rebirth // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg329_xmage_recursion_battlefield_simple_wave_20260701_2;

COMMIT;
