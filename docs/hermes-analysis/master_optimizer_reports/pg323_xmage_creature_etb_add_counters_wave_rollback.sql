BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('backup agent', 'bond beetle', 'cultbrand cinder', 'dauntless survivor', 'iron bully', 'ironpaw aspirant', 'ironshell beetle', 'jeong jeong''s deserters', 'pith driller', 'satyr grovedancer', 'supply-line cranes')
   OR normalized_name LIKE 'backup agent // %'
   OR normalized_name LIKE 'bond beetle // %'
   OR normalized_name LIKE 'cultbrand cinder // %'
   OR normalized_name LIKE 'dauntless survivor // %'
   OR normalized_name LIKE 'iron bully // %'
   OR normalized_name LIKE 'ironpaw aspirant // %'
   OR normalized_name LIKE 'ironshell beetle // %'
   OR normalized_name LIKE 'jeong jeong''s deserters // %'
   OR normalized_name LIKE 'pith driller // %'
   OR normalized_name LIKE 'satyr grovedancer // %'
   OR normalized_name LIKE 'supply-line cranes // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg323_xmage_creature_etb_add_counters_wave_20260701_1901;

COMMIT;
