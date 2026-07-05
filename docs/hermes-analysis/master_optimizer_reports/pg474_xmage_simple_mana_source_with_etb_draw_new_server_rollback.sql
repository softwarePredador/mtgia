BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('arcum''s astrolabe', 'energy refractor', 'llanowar visionary', 'prophetic prism')
   OR normalized_name LIKE 'arcum''s astrolabe // %'
   OR normalized_name LIKE 'energy refractor // %'
   OR normalized_name LIKE 'llanowar visionary // %'
   OR normalized_name LIKE 'prophetic prism // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg474_xmage_simple_mana_source_with_etb_draw_new_server_;

COMMIT;
