BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('doomed necromancer', 'protomatter powder')
   OR normalized_name LIKE 'doomed necromancer // %'
   OR normalized_name LIKE 'protomatter powder // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg348_xmage_activated_graveyard_to_battlefield_wave_2026;

COMMIT;
