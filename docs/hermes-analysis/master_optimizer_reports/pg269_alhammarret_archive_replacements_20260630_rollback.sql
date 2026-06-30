BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('alhammarret''s archive')
   OR normalized_name LIKE 'alhammarret''s archive // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg269_alhammarret_archive_replacements_20260630_alhammar;

COMMIT;
