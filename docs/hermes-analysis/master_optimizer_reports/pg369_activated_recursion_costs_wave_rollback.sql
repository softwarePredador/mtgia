BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ghen, arcanum weaver', 'malevolent awakening', 'phyrexian reclamation', 'strands of night')
   OR normalized_name LIKE 'ghen, arcanum weaver // %'
   OR normalized_name LIKE 'malevolent awakening // %'
   OR normalized_name LIKE 'phyrexian reclamation // %'
   OR normalized_name LIKE 'strands of night // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg369_activated_recursion_costs_wave_20260702_101411;

COMMIT;
