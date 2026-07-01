BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('advance scout', 'harmattan efreet', 'pixie queen', 'pseudodragon familiar', 'wind dancer')
   OR normalized_name LIKE 'advance scout // %'
   OR normalized_name LIKE 'harmattan efreet // %'
   OR normalized_name LIKE 'pixie queen // %'
   OR normalized_name LIKE 'pseudodragon familiar // %'
   OR normalized_name LIKE 'wind dancer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg317_xmage_permanent_activated_target_keyword_static_se;

COMMIT;
