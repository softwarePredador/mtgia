BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('altar''s reap', 'blood divination', 'corrupted conviction', 'costly plunder', 'eviscerator''s insight', 'magmatic insight', 'morbid curiosity', 'skulltap', 'tormenting voice', 'village rites', 'vivisection', 'wild guess')
   OR normalized_name LIKE 'altar''s reap // %'
   OR normalized_name LIKE 'blood divination // %'
   OR normalized_name LIKE 'corrupted conviction // %'
   OR normalized_name LIKE 'costly plunder // %'
   OR normalized_name LIKE 'eviscerator''s insight // %'
   OR normalized_name LIKE 'magmatic insight // %'
   OR normalized_name LIKE 'morbid curiosity // %'
   OR normalized_name LIKE 'skulltap // %'
   OR normalized_name LIKE 'tormenting voice // %'
   OR normalized_name LIKE 'village rites // %'
   OR normalized_name LIKE 'vivisection // %'
   OR normalized_name LIKE 'wild guess // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg450_xmage_fixed_draw_spell_new_server_20260704_233122;

COMMIT;
