BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aerial volley', 'arc lightning', 'boulderfall', 'chandra''s pyrohelix', 'deft dismissal', 'fire at will', 'flames of the firebrand', 'forked bolt', 'forked lightning', 'ignite disorder', 'magic missile', 'pyrotechnics', 'roil''s retribution', 'spreading flames', 'twin bolt')
   OR normalized_name LIKE 'aerial volley // %'
   OR normalized_name LIKE 'arc lightning // %'
   OR normalized_name LIKE 'boulderfall // %'
   OR normalized_name LIKE 'chandra''s pyrohelix // %'
   OR normalized_name LIKE 'deft dismissal // %'
   OR normalized_name LIKE 'fire at will // %'
   OR normalized_name LIKE 'flames of the firebrand // %'
   OR normalized_name LIKE 'forked bolt // %'
   OR normalized_name LIKE 'forked lightning // %'
   OR normalized_name LIKE 'ignite disorder // %'
   OR normalized_name LIKE 'magic missile // %'
   OR normalized_name LIKE 'pyrotechnics // %'
   OR normalized_name LIKE 'roil''s retribution // %'
   OR normalized_name LIKE 'spreading flames // %'
   OR normalized_name LIKE 'twin bolt // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg593_multi_target_damage_new_server_20260707_043446;

COMMIT;
