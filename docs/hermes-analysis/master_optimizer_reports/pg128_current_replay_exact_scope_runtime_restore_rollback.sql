BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('borne upon a wind', 'red elemental blast', 'consecrated sphinx', 'cyclonic rift', 'soul-guide lantern');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg128_current_replay_exact_scope_runtime_restore_2026062;

COMMIT;
