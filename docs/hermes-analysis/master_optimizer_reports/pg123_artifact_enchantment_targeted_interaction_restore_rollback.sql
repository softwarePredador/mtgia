BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aura of silence', 'nature''s claim', 'seal of primordium');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg123_artifact_enchantment_targeted_interaction_restore_;

COMMIT;
