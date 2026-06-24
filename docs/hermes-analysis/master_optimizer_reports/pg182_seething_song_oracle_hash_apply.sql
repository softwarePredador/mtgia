BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg182_seething_song_oracle_hash_20260624 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

WITH expected AS (
  SELECT
    'seething song'::text AS normalized_name,
    'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'::text AS logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS oracle_hash
  FROM public.cards c
  WHERE lower(c.name) = 'seething song'
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = expected.oracle_hash,
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG182: restored Seething Song oracle_hash after PG -> Hermes sync provenance audit.')
  FROM expected
  WHERE r.normalized_name = expected.normalized_name
    AND r.logical_rule_key = expected.logical_rule_key
    AND (r.oracle_hash IS DISTINCT FROM expected.oracle_hash)
  RETURNING r.*
)
SELECT count(*) AS updated_rows FROM updated;

COMMIT;
