BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('badlands revival', 'bonecaller cleric', 'crucible of worlds', 'elvish hexhunter', 'eternal taskmaster', 'festive funeral', 'ghoul''s feast', 'hana kami', 'pillardrop warden', 'pull through the weft', 'ramunap excavator', 'select for inspection', 'the unspeakable', 'valgavoth''s faithful', 'voyage''s end')
   OR normalized_name LIKE 'badlands revival // %'
   OR normalized_name LIKE 'bonecaller cleric // %'
   OR normalized_name LIKE 'crucible of worlds // %'
   OR normalized_name LIKE 'elvish hexhunter // %'
   OR normalized_name LIKE 'eternal taskmaster // %'
   OR normalized_name LIKE 'festive funeral // %'
   OR normalized_name LIKE 'ghoul''s feast // %'
   OR normalized_name LIKE 'hana kami // %'
   OR normalized_name LIKE 'pillardrop warden // %'
   OR normalized_name LIKE 'pull through the weft // %'
   OR normalized_name LIKE 'ramunap excavator // %'
   OR normalized_name LIKE 'select for inspection // %'
   OR normalized_name LIKE 'the unspeakable // %'
   OR normalized_name LIKE 'valgavoth''s faithful // %'
   OR normalized_name LIKE 'voyage''s end // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg478_xmage_residual_exact_safe_sweep_new_server_2026070;

COMMIT;
