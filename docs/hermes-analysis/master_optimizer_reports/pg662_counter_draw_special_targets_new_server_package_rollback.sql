BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('confound', 'hindering light', 'intervene', 'keep safe', 'laquatus''s disdain', 'rebuff the wicked', 'turn aside')
   OR normalized_name LIKE 'confound // %'
   OR normalized_name LIKE 'hindering light // %'
   OR normalized_name LIKE 'intervene // %'
   OR normalized_name LIKE 'keep safe // %'
   OR normalized_name LIKE 'laquatus''s disdain // %'
   OR normalized_name LIKE 'rebuff the wicked // %'
   OR normalized_name LIKE 'turn aside // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg662_counter_draw_special_targets_new_s_20260708_145709;

COMMIT;
