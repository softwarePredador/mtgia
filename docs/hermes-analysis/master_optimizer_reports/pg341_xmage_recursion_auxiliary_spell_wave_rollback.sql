BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('morgue theft', 'mystic retrieval', 'unburial rites', 'unearth', 'wander in death')
   OR normalized_name LIKE 'morgue theft // %'
   OR normalized_name LIKE 'mystic retrieval // %'
   OR normalized_name LIKE 'unburial rites // %'
   OR normalized_name LIKE 'unearth // %'
   OR normalized_name LIKE 'wander in death // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg341_xmage_recursion_auxiliary_spell_wave_20260702_0037;

COMMIT;
