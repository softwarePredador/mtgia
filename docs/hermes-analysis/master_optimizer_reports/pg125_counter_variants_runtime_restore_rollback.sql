BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('pact of negation', 'swan song', 'an offer you can''t refuse', 'refute', 'wizard''s retort');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg125_counter_variants_runtime_restore_20260623_235642;

COMMIT;
