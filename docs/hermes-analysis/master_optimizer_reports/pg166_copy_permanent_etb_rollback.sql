BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('copy enchantment', 'mirrormade', 'phyrexian metamorph', 'clever impersonator', 'copy artifact')
   OR normalized_name LIKE 'copy enchantment // %'
   OR normalized_name LIKE 'mirrormade // %'
   OR normalized_name LIKE 'phyrexian metamorph // %'
   OR normalized_name LIKE 'clever impersonator // %'
   OR normalized_name LIKE 'copy artifact // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg166_copy_permanent_etb_20260624_111014;

COMMIT;
