BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('fierce guardianship', 'force of will', 'mindbreak trap', 'sevinne''s reclamation', 'abrupt decay', 'counterspell', 'deadly rollick', 'force of vigor', 'laughing mad', 'lightning bolt', 'negate', 'snapback', 'thrill of possibility', 'calamity of cinders', 'gut shot');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg119_current_replay_simple_runtime_batch_20260623_22251;

COMMIT;
