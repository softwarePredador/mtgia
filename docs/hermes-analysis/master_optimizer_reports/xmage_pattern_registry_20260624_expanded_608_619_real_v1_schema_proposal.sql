-- Read-only proposal. Do not apply without explicit PostgreSQL approval.
-- Purpose: persist XMage-derived pattern observations separately from executable card_battle_rules.

CREATE TABLE IF NOT EXISTS public.xmage_pattern_registry (
  pattern_id TEXT PRIMARY KEY,
  lane TEXT NOT NULL,
  family_id TEXT NOT NULL,
  effect TEXT NOT NULL,
  battle_model_scope TEXT NOT NULL,
  pattern_status TEXT NOT NULL,
  promotion_status TEXT NOT NULL DEFAULT 'shadow_only',
  can_execute_in_battle BOOLEAN NOT NULL DEFAULT FALSE,
  can_auto_promote_to_card_battle_rules BOOLEAN NOT NULL DEFAULT FALSE,
  card_count INTEGER NOT NULL DEFAULT 0,
  subpattern_count INTEGER NOT NULL DEFAULT 0,
  evidence_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  template_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  source_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_xmage_pattern_registry_shadow_execution CHECK (
    promotion_status <> 'shadow_only'
    OR (
      can_execute_in_battle = FALSE
      AND can_auto_promote_to_card_battle_rules = FALSE
    )
  )
);

CREATE INDEX IF NOT EXISTS idx_xmage_pattern_registry_family_scope
ON public.xmage_pattern_registry (family_id, effect, battle_model_scope);

CREATE INDEX IF NOT EXISTS idx_xmage_pattern_registry_status
ON public.xmage_pattern_registry (pattern_status, promotion_status);

CREATE INDEX IF NOT EXISTS idx_xmage_pattern_registry_evidence
ON public.xmage_pattern_registry USING GIN (evidence_json);
