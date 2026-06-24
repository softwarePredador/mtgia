BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('agatha''s soul cauldron', 'necropotence')
   OR normalized_name LIKE 'agatha''s soul cauldron // %'
   OR normalized_name LIKE 'necropotence // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg136_current_replay_exact_scope_batch_three_20260624_01;

COMMIT;
