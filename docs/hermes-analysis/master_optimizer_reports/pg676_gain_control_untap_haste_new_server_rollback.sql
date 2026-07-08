BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('act of treason', 'blind with anger', 'claim the firstborn', 'hijack', 'metallic mastery', 'threaten', 'wrangle')
   OR normalized_name LIKE 'act of treason // %'
   OR normalized_name LIKE 'blind with anger // %'
   OR normalized_name LIKE 'claim the firstborn // %'
   OR normalized_name LIKE 'hijack // %'
   OR normalized_name LIKE 'metallic mastery // %'
   OR normalized_name LIKE 'threaten // %'
   OR normalized_name LIKE 'wrangle // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg676_gain_control_untap_haste_20260708_230749;

COMMIT;
