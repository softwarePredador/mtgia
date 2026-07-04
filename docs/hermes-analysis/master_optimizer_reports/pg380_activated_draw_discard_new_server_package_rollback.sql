BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bloodfire mentor', 'captain of umbar', 'dragonborn looter', 'emmessi tome', 'erratic visionary', 'facet reader', 'hapless researcher', 'jalum tome', 'magus of the bazaar', 'merfolk looter', 'research assistant', 'soothsayer adept', 'teferi''s protege', 'thought courier', 'unfulfilled desires')
   OR normalized_name LIKE 'bloodfire mentor // %'
   OR normalized_name LIKE 'captain of umbar // %'
   OR normalized_name LIKE 'dragonborn looter // %'
   OR normalized_name LIKE 'emmessi tome // %'
   OR normalized_name LIKE 'erratic visionary // %'
   OR normalized_name LIKE 'facet reader // %'
   OR normalized_name LIKE 'hapless researcher // %'
   OR normalized_name LIKE 'jalum tome // %'
   OR normalized_name LIKE 'magus of the bazaar // %'
   OR normalized_name LIKE 'merfolk looter // %'
   OR normalized_name LIKE 'research assistant // %'
   OR normalized_name LIKE 'soothsayer adept // %'
   OR normalized_name LIKE 'teferi''s protege // %'
   OR normalized_name LIKE 'thought courier // %'
   OR normalized_name LIKE 'unfulfilled desires // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg380_activated_draw_discard_new_server_20260704_031144;

COMMIT;
