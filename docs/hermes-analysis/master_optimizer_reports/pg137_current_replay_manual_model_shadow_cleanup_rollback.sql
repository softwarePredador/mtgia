BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN (
  'everflowing chalice',
  'vexing bauble',
  'soul-guide lantern'
);

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg137_current_replay_manual_model_shadow_cleanup_20260624_02;

COMMIT;
