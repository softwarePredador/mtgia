BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('codex shredder')
   OR normalized_name LIKE 'codex shredder // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg273_codex_shredder_mill_recursion_20260630;

COMMIT;
