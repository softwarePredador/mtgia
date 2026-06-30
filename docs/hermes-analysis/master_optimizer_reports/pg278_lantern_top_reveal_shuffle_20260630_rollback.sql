BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('lantern of insight')
   OR normalized_name LIKE 'lantern of insight // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg278_lantern_top_reveal_shuffle_20260630_120528;

COMMIT;
