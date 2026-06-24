BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg182_seething_song_oracle_hash_20260624;

COMMIT;
