BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ancestor''s chosen', 'angel of renewal', 'archway angel', 'aven gagglemaster', 'dwarven priest', 'flourishing hunter', 'goldnight redeemer', 'kraul foragers', 'luminollusk', 'nylea''s disciple', 'setessan petitioner', 'shepherd of heroes')
   OR normalized_name LIKE 'ancestor''s chosen // %'
   OR normalized_name LIKE 'angel of renewal // %'
   OR normalized_name LIKE 'archway angel // %'
   OR normalized_name LIKE 'aven gagglemaster // %'
   OR normalized_name LIKE 'dwarven priest // %'
   OR normalized_name LIKE 'flourishing hunter // %'
   OR normalized_name LIKE 'goldnight redeemer // %'
   OR normalized_name LIKE 'kraul foragers // %'
   OR normalized_name LIKE 'luminollusk // %'
   OR normalized_name LIKE 'nylea''s disciple // %'
   OR normalized_name LIKE 'setessan petitioner // %'
   OR normalized_name LIKE 'shepherd of heroes // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg557_etb_dynamic_life_gain_new_server_e_20260706_071903;

COMMIT;
