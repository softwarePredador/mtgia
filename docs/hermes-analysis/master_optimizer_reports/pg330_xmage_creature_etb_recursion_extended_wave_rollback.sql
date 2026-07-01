BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('barrow witches', 'disciple of the sun', 'leonin squire', 'pillardrop rescuer', 'ragamuffin raptor', 'scholar of the ages', 'strongarm thug')
   OR normalized_name LIKE 'barrow witches // %'
   OR normalized_name LIKE 'disciple of the sun // %'
   OR normalized_name LIKE 'leonin squire // %'
   OR normalized_name LIKE 'pillardrop rescuer // %'
   OR normalized_name LIKE 'ragamuffin raptor // %'
   OR normalized_name LIKE 'scholar of the ages // %'
   OR normalized_name LIKE 'strongarm thug // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg330_xmage_creature_etb_recursion_extended_wave_2026070;

COMMIT;
