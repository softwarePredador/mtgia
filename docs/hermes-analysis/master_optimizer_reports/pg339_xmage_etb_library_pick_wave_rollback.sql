BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('organ hoarder', 'sibsig appraiser', 'sultai soothsayer', 'tower geist')
   OR normalized_name LIKE 'organ hoarder // %'
   OR normalized_name LIKE 'sibsig appraiser // %'
   OR normalized_name LIKE 'sultai soothsayer // %'
   OR normalized_name LIKE 'tower geist // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg339_xmage_etb_library_pick_wave_pg339_xmage_etb_librar;

COMMIT;
