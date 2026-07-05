BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('inspiration', 'opportunity', 'overflowing insight')
   OR normalized_name LIKE 'inspiration // %'
   OR normalized_name LIKE 'opportunity // %'
   OR normalized_name LIKE 'overflowing insight // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg477_xmage_fixed_target_player_draw_spell_new_server_20;

COMMIT;
