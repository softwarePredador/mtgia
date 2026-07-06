BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('crash the party', 'deploy to the front', 'fungal sprouting', 'goblin gathering', 'howl of the night pack')
   OR normalized_name LIKE 'crash the party // %'
   OR normalized_name LIKE 'deploy to the front // %'
   OR normalized_name LIKE 'fungal sprouting // %'
   OR normalized_name LIKE 'goblin gathering // %'
   OR normalized_name LIKE 'howl of the night pack // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg547_dynamic_token_counts_new_server_dy_20260706_033924;

COMMIT;
