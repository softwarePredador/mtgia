BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('epitaph golem', 'haunted crossroads', 'tomb trawler')
   OR normalized_name LIKE 'epitaph golem // %'
   OR normalized_name LIKE 'haunted crossroads // %'
   OR normalized_name LIKE 'tomb trawler // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg336_xmage_activated_graveyard_to_library_wave_pg336_xm;

COMMIT;
