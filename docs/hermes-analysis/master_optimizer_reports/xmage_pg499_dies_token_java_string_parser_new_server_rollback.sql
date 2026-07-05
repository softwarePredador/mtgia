BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('conclave cavalier', 'mausoleum guard')
   OR normalized_name LIKE 'conclave cavalier // %'
   OR normalized_name LIKE 'mausoleum guard // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg499_dies_token_java_string_parse_20260705_101611;

COMMIT;
