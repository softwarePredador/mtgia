BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('argivian restoration', 'breath of life', 'false defeat', 'obzedat''s aid', 'refurbish', 'resurrection', 'rise again', 'zombify')
   OR normalized_name LIKE 'argivian restoration // %'
   OR normalized_name LIKE 'breath of life // %'
   OR normalized_name LIKE 'false defeat // %'
   OR normalized_name LIKE 'obzedat''s aid // %'
   OR normalized_name LIKE 'refurbish // %'
   OR normalized_name LIKE 'resurrection // %'
   OR normalized_name LIKE 'rise again // %'
   OR normalized_name LIKE 'zombify // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg300_xmage_recursion_battlefield_spell_wave_20260701_11;

COMMIT;
