BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('downpour', 'early frost', 'gridlock', 'lead astray', 'terashi''s cry', 'word of binding')
   OR normalized_name LIKE 'downpour // %'
   OR normalized_name LIKE 'early frost // %'
   OR normalized_name LIKE 'gridlock // %'
   OR normalized_name LIKE 'lead astray // %'
   OR normalized_name LIKE 'terashi''s cry // %'
   OR normalized_name LIKE 'word of binding // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg671_tap_target_spell_new_server_20260708_201937;

COMMIT;
