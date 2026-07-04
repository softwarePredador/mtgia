BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('agent of stromgald', 'arcum''s astrolabe', 'bog initiate', 'energy refractor', 'helionaut', 'llanowar envoy', 'llanowar visionary', 'nomadic elf', 'orochi leafcaller', 'prismite', 'prophetic prism', 'signpost scarecrow', 'viridian acolyte')
   OR normalized_name LIKE 'agent of stromgald // %'
   OR normalized_name LIKE 'arcum''s astrolabe // %'
   OR normalized_name LIKE 'bog initiate // %'
   OR normalized_name LIKE 'energy refractor // %'
   OR normalized_name LIKE 'helionaut // %'
   OR normalized_name LIKE 'llanowar envoy // %'
   OR normalized_name LIKE 'llanowar visionary // %'
   OR normalized_name LIKE 'nomadic elf // %'
   OR normalized_name LIKE 'orochi leafcaller // %'
   OR normalized_name LIKE 'prismite // %'
   OR normalized_name LIKE 'prophetic prism // %'
   OR normalized_name LIKE 'signpost scarecrow // %'
   OR normalized_name LIKE 'viridian acolyte // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg408_mana_etb_draw_new_server_mana_etb_draw_new_server_;

COMMIT;
