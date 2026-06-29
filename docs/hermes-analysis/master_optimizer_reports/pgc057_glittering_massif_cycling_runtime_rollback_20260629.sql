BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'glittering massif'
  AND logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pgc057_glittering_massif_cycling_runtime_20260629;

COMMIT;
