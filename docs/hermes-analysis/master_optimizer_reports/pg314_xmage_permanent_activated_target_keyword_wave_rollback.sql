BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('akki drillmaster', 'caller of gales', 'elvish herder', 'flying carpet', 'fyndhorn bow', 'icatian scout', 'iron lance', 'keen glidemaster', 'noble steeds', 'taxi driver', 'war chariot', 'zephyr charge')
   OR normalized_name LIKE 'akki drillmaster // %'
   OR normalized_name LIKE 'caller of gales // %'
   OR normalized_name LIKE 'elvish herder // %'
   OR normalized_name LIKE 'flying carpet // %'
   OR normalized_name LIKE 'fyndhorn bow // %'
   OR normalized_name LIKE 'icatian scout // %'
   OR normalized_name LIKE 'iron lance // %'
   OR normalized_name LIKE 'keen glidemaster // %'
   OR normalized_name LIKE 'noble steeds // %'
   OR normalized_name LIKE 'taxi driver // %'
   OR normalized_name LIKE 'war chariot // %'
   OR normalized_name LIKE 'zephyr charge // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg314_xmage_permanent_activated_target_keyword_wave_2026;

COMMIT;
