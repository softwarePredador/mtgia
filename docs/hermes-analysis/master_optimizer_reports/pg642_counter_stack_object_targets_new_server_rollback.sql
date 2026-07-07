BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('disallow', 'stern scolding', 'tale''s end', 'voidslime')
   OR normalized_name LIKE 'disallow // %'
   OR normalized_name LIKE 'stern scolding // %'
   OR normalized_name LIKE 'tale''s end // %'
   OR normalized_name LIKE 'voidslime // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg642_counter_stack_object_targets_new_s_20260707_213839;

COMMIT;
