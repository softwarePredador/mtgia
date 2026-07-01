BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('commune with the gods', 'glacial revelation', 'grisly salvage', 'kruphix''s insight', 'pieces of the puzzle', 'scout the borders')
   OR normalized_name LIKE 'commune with the gods // %'
   OR normalized_name LIKE 'glacial revelation // %'
   OR normalized_name LIKE 'grisly salvage // %'
   OR normalized_name LIKE 'kruphix''s insight // %'
   OR normalized_name LIKE 'pieces of the puzzle // %'
   OR normalized_name LIKE 'scout the borders // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg338_xmage_reveal_library_pick_wave_pg338_xmage_reveal_;

COMMIT;
