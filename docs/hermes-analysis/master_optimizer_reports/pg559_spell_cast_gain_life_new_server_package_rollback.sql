BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('contemplation', 'dawnhart geist', 'god-pharaoh''s faithful', 'student of ojutai')
   OR normalized_name LIKE 'contemplation // %'
   OR normalized_name LIKE 'dawnhart geist // %'
   OR normalized_name LIKE 'god-pharaoh''s faithful // %'
   OR normalized_name LIKE 'student of ojutai // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg559_spell_cast_gain_life_new_server_sp_20260706_100650;

COMMIT;
