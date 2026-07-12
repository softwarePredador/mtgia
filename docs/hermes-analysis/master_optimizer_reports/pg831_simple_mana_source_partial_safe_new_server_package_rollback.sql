BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('codie, vociferous codex', 'strixhaven stadium')
   OR normalized_name LIKE 'codie, vociferous codex // %'
   OR normalized_name LIKE 'strixhaven stadium // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg831_simple_mana_source_partial_safe_ne_20260712_124708;

COMMIT;
