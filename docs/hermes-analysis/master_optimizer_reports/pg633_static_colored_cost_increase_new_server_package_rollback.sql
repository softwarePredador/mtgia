BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('alabaster leech', 'derelor', 'jade leech', 'ruby leech', 'sapphire leech')
   OR normalized_name LIKE 'alabaster leech // %'
   OR normalized_name LIKE 'derelor // %'
   OR normalized_name LIKE 'jade leech // %'
   OR normalized_name LIKE 'ruby leech // %'
   OR normalized_name LIKE 'sapphire leech // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg633_static_colored_cost_increase_new_s_20260707_192935;

COMMIT;
