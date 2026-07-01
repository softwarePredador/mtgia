BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dukhara scavenger', 'meldweb curator')
   OR normalized_name LIKE 'dukhara scavenger // %'
   OR normalized_name LIKE 'meldweb curator // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg337_xmage_etb_graveyard_to_library_wave_pg337_xmage_et;

COMMIT;
