BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('birgi, god of storytelling')
   OR normalized_name LIKE 'birgi, god of storytelling // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg867_birgi_registry_alignment_new_serve_20260715_153348;

COMMIT;
