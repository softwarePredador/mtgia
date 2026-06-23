BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('pearl medallion', 'the scarlet witch');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.preview_static_cost_deck607_static_cost_reducer_preview_;

COMMIT;
