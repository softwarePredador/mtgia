BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dwell on the past', 'krosan reclamation', 'memory''s journey', 'stream of consciousness')
   OR normalized_name LIKE 'dwell on the past // %'
   OR normalized_name LIKE 'krosan reclamation // %'
   OR normalized_name LIKE 'memory''s journey // %'
   OR normalized_name LIKE 'stream of consciousness // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg352_xmage_graveyard_shuffle_to_library_spell_wave_2026;

COMMIT;
