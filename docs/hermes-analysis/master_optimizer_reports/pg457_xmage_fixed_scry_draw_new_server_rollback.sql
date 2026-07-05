BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('behold the multiverse', 'deliberate', 'foresee', 'introduction to prophecy', 'opt', 'preordain', 'scour all possibilities', 'serum visions', 'tamiyo''s epiphany')
   OR normalized_name LIKE 'behold the multiverse // %'
   OR normalized_name LIKE 'deliberate // %'
   OR normalized_name LIKE 'foresee // %'
   OR normalized_name LIKE 'introduction to prophecy // %'
   OR normalized_name LIKE 'opt // %'
   OR normalized_name LIKE 'preordain // %'
   OR normalized_name LIKE 'scour all possibilities // %'
   OR normalized_name LIKE 'serum visions // %'
   OR normalized_name LIKE 'tamiyo''s epiphany // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg457_xmage_fixed_scry_draw_new_server_20260705_002433;

COMMIT;
