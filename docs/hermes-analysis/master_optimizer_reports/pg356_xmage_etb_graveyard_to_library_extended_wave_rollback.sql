BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('biblioplex assistant', 'monastery messenger', 'nantuko tracer', 'swiftgear drake')
   OR normalized_name LIKE 'biblioplex assistant // %'
   OR normalized_name LIKE 'monastery messenger // %'
   OR normalized_name LIKE 'nantuko tracer // %'
   OR normalized_name LIKE 'swiftgear drake // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg356_xmage_etb_graveyard_to_library_extended_wave_xmage;

COMMIT;
