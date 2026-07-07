BEGIN;

DELETE FROM public.card_battle_rules
WHERE reviewed_by = 'codex-pg644-oracle-identity-rule-link'
  AND card_id IN (
    'db2d9112-7066-44cb-beea-29e30ade8fe3'::uuid,
    'c971ff63-79d9-45e4-a7d9-4aec4eecd525'::uuid
  )
  AND logical_rule_key IN (
    'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba',
    'battle_rule_v1:42621fcae461313f674d46db0da059af'
  );

UPDATE public.card_battle_rules r
SET
  effect_json = b.effect_json,
  deck_role_json = b.deck_role_json,
  notes = b.notes,
  reviewed_by = b.reviewed_by,
  reviewed_at = b.reviewed_at,
  updated_at = now(),
  last_seen_at = b.last_seen_at
FROM manaloom_deploy_audit.pg644_oracle_identity_mana_source_role_link_20260707 b
WHERE r.card_id = b.card_id
  AND r.logical_rule_key = b.logical_rule_key
  AND r.card_id IN (
    '037e2cf5-cd46-4d03-975d-fb877e4de51a'::uuid,
    '083da955-e31c-4d6b-a0f1-dfdf1569d9d8'::uuid
  )
  AND r.logical_rule_key IN (
    'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba',
    'battle_rule_v1:42621fcae461313f674d46db0da059af'
  );

COMMIT;
