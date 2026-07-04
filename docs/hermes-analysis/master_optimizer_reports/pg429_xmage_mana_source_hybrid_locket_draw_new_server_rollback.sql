BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('azorius locket', 'boros locket', 'dimir locket', 'golgari locket', 'gruul locket', 'izzet locket', 'orzhov locket', 'rakdos locket', 'selesnya locket', 'simic locket')
   OR normalized_name LIKE 'azorius locket // %'
   OR normalized_name LIKE 'boros locket // %'
   OR normalized_name LIKE 'dimir locket // %'
   OR normalized_name LIKE 'golgari locket // %'
   OR normalized_name LIKE 'gruul locket // %'
   OR normalized_name LIKE 'izzet locket // %'
   OR normalized_name LIKE 'orzhov locket // %'
   OR normalized_name LIKE 'rakdos locket // %'
   OR normalized_name LIKE 'selesnya locket // %'
   OR normalized_name LIKE 'simic locket // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg429_xmage_mana_source_hybrid_locket_draw_new_server_20;

COMMIT;
