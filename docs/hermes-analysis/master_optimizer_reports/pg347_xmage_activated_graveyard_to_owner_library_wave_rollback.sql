BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cogwork archivist', 'jade-cast sentinel', 'junktroller', 'phyrexian archivist', 'reito lantern')
   OR normalized_name LIKE 'cogwork archivist // %'
   OR normalized_name LIKE 'jade-cast sentinel // %'
   OR normalized_name LIKE 'junktroller // %'
   OR normalized_name LIKE 'phyrexian archivist // %'
   OR normalized_name LIKE 'reito lantern // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg347_xmage_activated_graveyard_to_owner_library_wave_20;

COMMIT;
