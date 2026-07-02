BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('kraul swarm', 'summoned dromedary')
   OR normalized_name LIKE 'kraul swarm // %'
   OR normalized_name LIKE 'summoned dromedary // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg351_xmage_graveyard_self_return_hand_discard_creature_;

COMMIT;
