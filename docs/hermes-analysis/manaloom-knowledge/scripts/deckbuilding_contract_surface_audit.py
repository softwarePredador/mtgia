#!/usr/bin/env python3
"""Audit active Commander deckbuilding surfaces against the frozen contract."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

CONTRACT_DOC = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
SUPPORT_FILE = REPO_ROOT / "server/lib/ai/commander_deckbuilding_contract_support.dart"
REFERENCE_PROFILE_SUPPORT_FILE = REPO_ROOT / "server/lib/ai/commander_reference_profile_support.dart"
STAPLE_POLICY_FILE = REPO_ROOT / "server/lib/ai/commander_staple_impact_policy.dart"
REBUILD_GUIDED_SERVICE = REPO_ROOT / "server/lib/ai/rebuild_guided_service.dart"
GENERATE_ROUTE = REPO_ROOT / "server/routes/ai/generate/index.dart"
SUPPORT_TEST = REPO_ROOT / "server/test/commander_deckbuilding_contract_support_test.dart"
BATTLE_ANALYST = SCRIPT_DIR / "battle_analyst_v9.py"
GLOBAL_COMMANDER_FORCE_FOCUS_ACCESS_SCOPE_TEST = (
    SCRIPT_DIR / "test_global_commander_force_focus_access_scope.py"
)
VARIANT_MATRIX = SCRIPT_DIR / "lorehold_variant_strategy_matrix.py"
VARIANT_GATE = SCRIPT_DIR / "lorehold_variant_battle_gate.py"
ARTIFACT_CONTRACT_AUDIT = SCRIPT_DIR / "lorehold_artifact_contract_audit.py"
PROMOTION_DECISION_AUDIT = SCRIPT_DIR / "lorehold_promotion_gate_decision_audit.py"
GLOBAL_COMMANDER_AUDIT = SCRIPT_DIR / "global_commander_deck_contract_audit.py"
GLOBAL_COMMANDER_MATRIX = SCRIPT_DIR / "global_commander_strategy_matrix.py"
GLOBAL_COMMANDER_CORE_ROLE_AUDIT = SCRIPT_DIR / "global_commander_core_role_audit.py"
GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS = SCRIPT_DIR / "global_commander_core_repair_hypothesis.py"
GLOBAL_COMMANDER_MANA_BASE_PROFILE = SCRIPT_DIR / "global_commander_mana_base_profile.py"
GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL = SCRIPT_DIR / "global_commander_named_land_candidate_pool.py"
GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL = SCRIPT_DIR / "global_commander_land_cut_candidate_model.py"
GLOBAL_COMMANDER_LAND_FLOOR_POLICY_BUILDER = SCRIPT_DIR / "global_commander_land_floor_policy_builder.py"
GLOBAL_COMMANDER_LAND_FLOOR_POLICY_BUILDER_TEST = (
    SCRIPT_DIR / "test_global_commander_land_floor_policy_builder.py"
)
GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_SYNTHESIZER = SCRIPT_DIR / "global_commander_land_floor_package_synthesizer.py"
GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_SYNTHESIZER_TEST = (
    SCRIPT_DIR / "test_global_commander_land_floor_package_synthesizer.py"
)
GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL = SCRIPT_DIR / "global_commander_nonland_core_candidate_model.py"
GLOBAL_COMMANDER_LEARNING_PRIORITY_AUDIT = SCRIPT_DIR / "global_commander_learning_priority_audit.py"
GLOBAL_COMMANDER_CROSS_COMMANDER_ROLE_AXIS_LEARNING_PIVOT = (
    SCRIPT_DIR / "global_commander_cross_commander_role_axis_learning_pivot.py"
)
GLOBAL_COMMANDER_CROSS_COMMANDER_ROLE_AXIS_LEARNING_PIVOT_TEST = (
    SCRIPT_DIR / "test_global_commander_cross_commander_role_axis_learning_pivot.py"
)
GLOBAL_COMMANDER_ROLE_AXIS_POLICY_BUILDER = SCRIPT_DIR / "global_commander_role_axis_policy_builder.py"
GLOBAL_COMMANDER_ROLE_AXIS_POLICY_BUILDER_TEST = (
    SCRIPT_DIR / "test_global_commander_role_axis_policy_builder.py"
)
GLOBAL_COMMANDER_ENGINE_AXIS_NONLAND_CUT_POLICY_MODEL = (
    SCRIPT_DIR / "global_commander_engine_axis_nonland_cut_policy_model.py"
)
GLOBAL_COMMANDER_ENGINE_AXIS_NONLAND_CUT_POLICY_MODEL_TEST = (
    SCRIPT_DIR / "test_global_commander_engine_axis_nonland_cut_policy_model.py"
)
GLOBAL_COMMANDER_RAMP_AXIS_NONLAND_CUT_POLICY_MODEL = (
    SCRIPT_DIR / "global_commander_ramp_axis_nonland_cut_policy_model.py"
)
GLOBAL_COMMANDER_RAMP_AXIS_NONLAND_CUT_POLICY_MODEL_TEST = (
    SCRIPT_DIR / "test_global_commander_ramp_axis_nonland_cut_policy_model.py"
)
GLOBAL_COMMANDER_RAMP_CUT_USAGE_SAME_LANE_PROOF_SCOUT = (
    SCRIPT_DIR / "global_commander_ramp_cut_usage_same_lane_proof_scout.py"
)
GLOBAL_COMMANDER_RAMP_CUT_USAGE_SAME_LANE_PROOF_SCOUT_TEST = (
    SCRIPT_DIR / "test_global_commander_ramp_cut_usage_same_lane_proof_scout.py"
)
GLOBAL_COMMANDER_RAMP_CUT_FOLLOWUP_ROUTER = (
    SCRIPT_DIR / "global_commander_ramp_cut_followup_router.py"
)
GLOBAL_COMMANDER_RAMP_CUT_FOLLOWUP_ROUTER_TEST = (
    SCRIPT_DIR / "test_global_commander_ramp_cut_followup_router.py"
)
GLOBAL_COMMANDER_RAMP_CUT_TRACE_REPLACEMENT_GATE = (
    SCRIPT_DIR / "global_commander_ramp_cut_trace_replacement_gate.py"
)
GLOBAL_COMMANDER_RAMP_CUT_TRACE_REPLACEMENT_GATE_TEST = (
    SCRIPT_DIR / "test_global_commander_ramp_cut_trace_replacement_gate.py"
)
GLOBAL_COMMANDER_RAMP_CUT_FORCED_ACCESS_TRACE_GENERATOR = (
    SCRIPT_DIR / "global_commander_ramp_cut_forced_access_trace_generator.py"
)
GLOBAL_COMMANDER_RAMP_CUT_FORCED_ACCESS_TRACE_GENERATOR_TEST = (
    SCRIPT_DIR / "test_global_commander_ramp_cut_forced_access_trace_generator.py"
)
GLOBAL_COMMANDER_RAMP_CUT_FORCED_RECOVERY_ROUTER = (
    SCRIPT_DIR / "global_commander_ramp_cut_forced_recovery_router.py"
)
GLOBAL_COMMANDER_RAMP_CUT_FORCED_RECOVERY_ROUTER_TEST = (
    SCRIPT_DIR / "test_global_commander_ramp_cut_forced_recovery_router.py"
)
GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_TRACE_GENERATOR = (
    SCRIPT_DIR / "global_commander_ramp_alternative_cut_trace_generator.py"
)
GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_TRACE_GENERATOR_TEST = (
    SCRIPT_DIR / "test_global_commander_ramp_alternative_cut_trace_generator.py"
)
GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_FORCED_ACCESS_TRACE_GENERATOR = (
    SCRIPT_DIR / "global_commander_ramp_alternative_cut_forced_access_trace_generator.py"
)
GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_FORCED_ACCESS_TRACE_GENERATOR_TEST = (
    SCRIPT_DIR / "test_global_commander_ramp_alternative_cut_forced_access_trace_generator.py"
)
GLOBAL_COMMANDER_RAMP_AXIS_EXHAUSTION_ROUTER = (
    SCRIPT_DIR / "global_commander_ramp_axis_exhaustion_router.py"
)
GLOBAL_COMMANDER_RAMP_AXIS_EXHAUSTION_ROUTER_TEST = (
    SCRIPT_DIR / "test_global_commander_ramp_axis_exhaustion_router.py"
)
GLOBAL_COMMANDER_ENGINE_CUT_USAGE_SAME_LANE_PROOF_SCOUT = (
    SCRIPT_DIR / "global_commander_engine_cut_usage_same_lane_proof_scout.py"
)
GLOBAL_COMMANDER_ENGINE_CUT_USAGE_SAME_LANE_PROOF_SCOUT_TEST = (
    SCRIPT_DIR / "test_global_commander_engine_cut_usage_same_lane_proof_scout.py"
)
GLOBAL_COMMANDER_ENGINE_CUT_FOLLOWUP_ROUTER = (
    SCRIPT_DIR / "global_commander_engine_cut_followup_router.py"
)
GLOBAL_COMMANDER_ENGINE_CUT_FOLLOWUP_ROUTER_TEST = (
    SCRIPT_DIR / "test_global_commander_engine_cut_followup_router.py"
)
GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_GATE = (
    SCRIPT_DIR / "global_commander_engine_cut_trace_replacement_gate.py"
)
GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_GATE_TEST = (
    SCRIPT_DIR / "test_global_commander_engine_cut_trace_replacement_gate.py"
)
GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_REVIEWER = (
    SCRIPT_DIR / "global_commander_engine_cut_trace_replacement_reviewer.py"
)
GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_REVIEWER_TEST = (
    SCRIPT_DIR / "test_global_commander_engine_cut_trace_replacement_reviewer.py"
)
GLOBAL_COMMANDER_ENGINE_EXACT_REPLACEMENT_OR_NEW_CUT_FINDER = (
    SCRIPT_DIR / "global_commander_engine_exact_replacement_or_new_cut_finder.py"
)
GLOBAL_COMMANDER_ENGINE_EXACT_REPLACEMENT_OR_NEW_CUT_FINDER_TEST = (
    SCRIPT_DIR / "test_global_commander_engine_exact_replacement_or_new_cut_finder.py"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_SOURCE_EXPANDER = (
    SCRIPT_DIR / "global_commander_external_exact_artifact_engine_source_expander.py"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_SOURCE_EXPANDER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_exact_artifact_engine_source_expander.py"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_CANDIDATE_REVIEWER = (
    SCRIPT_DIR / "global_commander_external_exact_artifact_engine_candidate_reviewer.py"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_CANDIDATE_REVIEWER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_exact_artifact_engine_candidate_reviewer.py"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ORACLE_BACKFILL = (
    SCRIPT_DIR / "global_commander_external_exact_artifact_oracle_backfill.py"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ORACLE_BACKFILL_TEST = (
    SCRIPT_DIR / "test_global_commander_external_exact_artifact_oracle_backfill.py"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_ADD_CUT_PAIR_MODEL = (
    SCRIPT_DIR / "global_commander_external_exact_artifact_engine_add_cut_pair_model.py"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_ADD_CUT_PAIR_MODEL_TEST = (
    SCRIPT_DIR / "test_global_commander_external_exact_artifact_engine_add_cut_pair_model.py"
)
GLOBAL_COMMANDER_EXACT_ARTIFACT_TYPE_CONVERSION_SOURCE_LANE_EXPANDER = (
    SCRIPT_DIR / "global_commander_exact_artifact_type_conversion_source_lane_expander.py"
)
GLOBAL_COMMANDER_EXACT_ARTIFACT_TYPE_CONVERSION_SOURCE_LANE_EXPANDER_TEST = (
    SCRIPT_DIR / "test_global_commander_exact_artifact_type_conversion_source_lane_expander.py"
)
GLOBAL_COMMANDER_BIOTRANSFERENCE_PROTECTION_PIVOT_ROUTER = (
    SCRIPT_DIR / "global_commander_biotransference_protection_pivot_router.py"
)
GLOBAL_COMMANDER_BIOTRANSFERENCE_PROTECTION_PIVOT_ROUTER_TEST = (
    SCRIPT_DIR / "test_global_commander_biotransference_protection_pivot_router.py"
)
GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER = SCRIPT_DIR / "global_commander_candidate_copy_materializer.py"
GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_TEST = (
    SCRIPT_DIR / "test_global_commander_candidate_copy_materializer.py"
)
GLOBAL_COMMANDER_CANDIDATE_BATTLE_PROBE_AUDIT = (
    SCRIPT_DIR / "global_commander_candidate_battle_probe_audit.py"
)
GLOBAL_COMMANDER_BATTLE_FEEDBACK_MODEL = SCRIPT_DIR / "global_commander_battle_feedback_model.py"
GLOBAL_COMMANDER_CANDIDATE_PACKAGE_CHAIN_AUDIT = (
    SCRIPT_DIR / "global_commander_candidate_package_chain_audit.py"
)
GLOBAL_COMMANDER_CANDIDATE_PACKAGE_CHAIN_AUDIT_TEST = (
    SCRIPT_DIR / "test_global_commander_candidate_package_chain_audit.py"
)
GLOBAL_COMMANDER_CANDIDATE_PACKAGE_STRATEGY_MATRIX = (
    SCRIPT_DIR / "global_commander_candidate_package_strategy_matrix.py"
)
GLOBAL_COMMANDER_PROFILE_BLOCKER_REPAIR_PLAN = (
    SCRIPT_DIR / "global_commander_profile_blocker_repair_plan.py"
)
GLOBAL_COMMANDER_PROFILE_REPAIR_CANDIDATE_MODEL = (
    SCRIPT_DIR / "global_commander_profile_repair_candidate_model.py"
)
GLOBAL_COMMANDER_PAYOFF_SOURCE_LANE_EXPANDER = (
    SCRIPT_DIR / "global_commander_payoff_source_lane_expander.py"
)
GLOBAL_COMMANDER_PAYOFF_PACKAGE_SYNTHESIZER = (
    SCRIPT_DIR / "global_commander_payoff_package_synthesizer.py"
)
GLOBAL_COMMANDER_CUT_SOURCE_LANE_EXPANDER = (
    SCRIPT_DIR / "global_commander_cut_source_lane_expander.py"
)
GLOBAL_COMMANDER_CUT_SOURCE_LANE_EXPANDER_TEST = (
    SCRIPT_DIR / "test_global_commander_cut_source_lane_expander.py"
)
GLOBAL_COMMANDER_VALUE_SAFE_STAGE_SPLITTER = (
    SCRIPT_DIR / "global_commander_value_safe_stage_splitter.py"
)
GLOBAL_COMMANDER_PACKAGE_SCOPE_REDUCER = SCRIPT_DIR / "global_commander_package_scope_reducer.py"
GLOBAL_COMMANDER_PACKAGE_SCOPE_REDUCER_TEST = SCRIPT_DIR / "test_global_commander_package_scope_reducer.py"
GLOBAL_COMMANDER_STAGE_ONLY_CUT_EVIDENCE_PLAN = (
    SCRIPT_DIR / "global_commander_stage_only_cut_evidence_plan.py"
)
GLOBAL_COMMANDER_STAGE_ONLY_CUT_EVIDENCE_PLAN_TEST = (
    SCRIPT_DIR / "test_global_commander_stage_only_cut_evidence_plan.py"
)
GLOBAL_COMMANDER_CONTEXTUAL_STAGE_CUT_EVIDENCE_COLLECTOR = (
    SCRIPT_DIR / "global_commander_contextual_stage_cut_evidence_collector.py"
)
GLOBAL_COMMANDER_CONTEXTUAL_STAGE_CUT_EVIDENCE_COLLECTOR_TEST = (
    SCRIPT_DIR / "test_global_commander_contextual_stage_cut_evidence_collector.py"
)
GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_SCOUT = (
    SCRIPT_DIR / "global_commander_contextual_usage_trace_scout.py"
)
GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_SCOUT_TEST = (
    SCRIPT_DIR / "test_global_commander_contextual_usage_trace_scout.py"
)
GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_GENERATOR = (
    SCRIPT_DIR / "global_commander_contextual_usage_trace_generator.py"
)
GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_GENERATOR_TEST = (
    SCRIPT_DIR / "test_global_commander_contextual_usage_trace_generator.py"
)
GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_REVIEWER = (
    SCRIPT_DIR / "global_commander_contextual_usage_trace_reviewer.py"
)
GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_REVIEWER_TEST = (
    SCRIPT_DIR / "test_global_commander_contextual_usage_trace_reviewer.py"
)
GLOBAL_COMMANDER_SAME_LANE_REPLACEMENT_MODEL = (
    SCRIPT_DIR / "global_commander_same_lane_replacement_model.py"
)
GLOBAL_COMMANDER_SAME_LANE_REPLACEMENT_MODEL_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_replacement_model.py"
)
GLOBAL_COMMANDER_NEW_CUT_SOURCE_LANE_TRACE_COLLECTOR = (
    SCRIPT_DIR / "global_commander_new_cut_source_lane_trace_collector.py"
)
GLOBAL_COMMANDER_NEW_CUT_SOURCE_LANE_TRACE_COLLECTOR_TEST = (
    SCRIPT_DIR / "test_global_commander_new_cut_source_lane_trace_collector.py"
)
GLOBAL_COMMANDER_FORCED_CUT_ACCESS_TRACE_GENERATOR = (
    SCRIPT_DIR / "global_commander_forced_cut_access_trace_generator.py"
)
GLOBAL_COMMANDER_FORCED_CUT_ACCESS_TRACE_GENERATOR_TEST = (
    SCRIPT_DIR / "test_global_commander_forced_cut_access_trace_generator.py"
)
GLOBAL_COMMANDER_POST_FORCED_RECOVERY_SYNTHESIZER = (
    SCRIPT_DIR / "global_commander_post_forced_recovery_synthesizer.py"
)
GLOBAL_COMMANDER_POST_FORCED_RECOVERY_SYNTHESIZER_TEST = (
    SCRIPT_DIR / "test_global_commander_post_forced_recovery_synthesizer.py"
)
GLOBAL_COMMANDER_VALUE_SAFE_CUT_SOURCE_MINER = (
    SCRIPT_DIR / "global_commander_value_safe_cut_source_miner.py"
)
GLOBAL_COMMANDER_VALUE_SAFE_CUT_SOURCE_MINER_TEST = (
    SCRIPT_DIR / "test_global_commander_value_safe_cut_source_miner.py"
)
GLOBAL_COMMANDER_CUT_SOURCE_HYPOTHESIS_TRACE_COLLECTOR = (
    SCRIPT_DIR / "global_commander_cut_source_hypothesis_trace_collector.py"
)
GLOBAL_COMMANDER_CUT_SOURCE_HYPOTHESIS_TRACE_COLLECTOR_TEST = (
    SCRIPT_DIR / "test_global_commander_cut_source_hypothesis_trace_collector.py"
)
GLOBAL_COMMANDER_CUT_HYPOTHESIS_SAME_LANE_PROOF = (
    SCRIPT_DIR / "global_commander_cut_hypothesis_same_lane_proof.py"
)
GLOBAL_COMMANDER_CUT_HYPOTHESIS_SAME_LANE_PROOF_TEST = (
    SCRIPT_DIR / "test_global_commander_cut_hypothesis_same_lane_proof.py"
)
GLOBAL_COMMANDER_EXTERNAL_CUT_SOURCE_RESEARCH_PLAN = (
    SCRIPT_DIR / "global_commander_external_cut_source_research_plan.py"
)
GLOBAL_COMMANDER_EXTERNAL_CUT_SOURCE_RESEARCH_PLAN_TEST = (
    SCRIPT_DIR / "test_global_commander_external_cut_source_research_plan.py"
)
GLOBAL_COMMANDER_EXTERNAL_REFERENCE_CORPUS_COLLECTOR = (
    SCRIPT_DIR / "global_commander_external_reference_corpus_collector.py"
)
GLOBAL_COMMANDER_EXTERNAL_REFERENCE_CORPUS_COLLECTOR_TEST = (
    SCRIPT_DIR / "test_global_commander_external_reference_corpus_collector.py"
)
GLOBAL_COMMANDER_EXTERNAL_CORPUS_CUT_POLICY_MAPPER = (
    SCRIPT_DIR / "global_commander_external_corpus_cut_policy_mapper.py"
)
GLOBAL_COMMANDER_EXTERNAL_CORPUS_CUT_POLICY_MAPPER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_corpus_cut_policy_mapper.py"
)
GLOBAL_COMMANDER_PACKAGE_AXIS_BROADENING_PLAN = (
    SCRIPT_DIR / "global_commander_package_axis_broadening_plan.py"
)
GLOBAL_COMMANDER_PACKAGE_AXIS_BROADENING_PLAN_TEST = (
    SCRIPT_DIR / "test_global_commander_package_axis_broadening_plan.py"
)
GLOBAL_COMMANDER_SAME_LANE_PACKAGE_RESYNTHESIZER = (
    SCRIPT_DIR / "global_commander_same_lane_package_resynthesizer.py"
)
GLOBAL_COMMANDER_SAME_LANE_PACKAGE_RESYNTHESIZER_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_package_resynthesizer.py"
)
GLOBAL_COMMANDER_SAME_LANE_ADD_SOURCE_LANE_EXPANDER = (
    SCRIPT_DIR / "global_commander_same_lane_add_source_lane_expander.py"
)
GLOBAL_COMMANDER_SAME_LANE_ADD_SOURCE_LANE_EXPANDER_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_add_source_lane_expander.py"
)
GLOBAL_COMMANDER_SAME_LANE_PACKAGE_SOURCE_SYNTHESIZER = (
    SCRIPT_DIR / "global_commander_same_lane_package_source_synthesizer.py"
)
GLOBAL_COMMANDER_SAME_LANE_PACKAGE_SOURCE_SYNTHESIZER_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_package_source_synthesizer.py"
)
GLOBAL_COMMANDER_SAME_LANE_CUT_PAIR_COLLECTOR = (
    SCRIPT_DIR / "global_commander_same_lane_cut_pair_collector.py"
)
GLOBAL_COMMANDER_SAME_LANE_CUT_PAIR_COLLECTOR_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_cut_pair_collector.py"
)
GLOBAL_COMMANDER_SAME_LANE_CUT_EVIDENCE_PLAN = (
    SCRIPT_DIR / "global_commander_same_lane_cut_evidence_plan.py"
)
GLOBAL_COMMANDER_SAME_LANE_CUT_EVIDENCE_PLAN_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_cut_evidence_plan.py"
)
GLOBAL_COMMANDER_SAME_LANE_STAGE_CUT_TRACE_COLLECTOR = (
    SCRIPT_DIR / "global_commander_same_lane_stage_cut_trace_collector.py"
)
GLOBAL_COMMANDER_SAME_LANE_STAGE_CUT_TRACE_COLLECTOR_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_stage_cut_trace_collector.py"
)
GLOBAL_COMMANDER_SAME_LANE_USED_CUT_RECOVERY_ROUTER = (
    SCRIPT_DIR / "global_commander_same_lane_used_cut_recovery_router.py"
)
GLOBAL_COMMANDER_SAME_LANE_USED_CUT_RECOVERY_ROUTER_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_used_cut_recovery_router.py"
)
GLOBAL_COMMANDER_SAME_LANE_NEW_CUT_SOURCE_MINER = (
    SCRIPT_DIR / "global_commander_same_lane_new_cut_source_miner.py"
)
GLOBAL_COMMANDER_SAME_LANE_NEW_CUT_SOURCE_MINER_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_new_cut_source_miner.py"
)
GLOBAL_COMMANDER_SAME_LANE_CUT_AXIS_BROADENING_PLAN = (
    SCRIPT_DIR / "global_commander_same_lane_cut_axis_broadening_plan.py"
)
GLOBAL_COMMANDER_SAME_LANE_CUT_AXIS_BROADENING_PLAN_TEST = (
    SCRIPT_DIR / "test_global_commander_same_lane_cut_axis_broadening_plan.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_CORPUS_COLLECTOR = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_same_lane_cut_corpus_collector.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_CORPUS_COLLECTOR_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_same_lane_cut_corpus_collector.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_POLICY_MAPPER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_same_lane_cut_policy_mapper.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_POLICY_MAPPER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_same_lane_cut_policy_mapper.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_DISCOVERER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_same_lane_source_candidate_discoverer.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_DISCOVERER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_same_lane_source_candidate_discoverer.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_REVIEWER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_REVIEWER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_same_lane_source_candidate_reviewer.py"
)
GLOBAL_COMMANDER_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER = (
    SCRIPT_DIR / "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner.py"
)
GLOBAL_COMMANDER_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_TEST = (
    SCRIPT_DIR / "test_global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner.py"
)
GLOBAL_COMMANDER_REVIEWED_EXTERNAL_SEEDED_CUT_TRACE_COLLECTOR = (
    SCRIPT_DIR / "global_commander_reviewed_external_seeded_cut_trace_collector.py"
)
GLOBAL_COMMANDER_REVIEWED_EXTERNAL_SEEDED_CUT_TRACE_COLLECTOR_TEST = (
    SCRIPT_DIR / "test_global_commander_reviewed_external_seeded_cut_trace_collector.py"
)
GLOBAL_COMMANDER_REVIEWED_EXTERNAL_SEEDED_FORCE_ACCESS_TRACE_GENERATOR = (
    SCRIPT_DIR / "global_commander_reviewed_external_seeded_force_access_trace_generator.py"
)
GLOBAL_COMMANDER_REVIEWED_EXTERNAL_SEEDED_FORCE_ACCESS_TRACE_GENERATOR_TEST = (
    SCRIPT_DIR / "test_global_commander_reviewed_external_seeded_force_access_trace_generator.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_seed_exhaustion_recovery_router.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_seed_exhaustion_recovery_router.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_current_deck_negative_review_collector.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_current_deck_negative_review_collector.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_MANUAL_NEGATIVE_TRACE_REVIEWER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_manual_negative_trace_reviewer.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_MANUAL_NEGATIVE_TRACE_REVIEWER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_manual_negative_trace_reviewer.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_NEW_SOURCE_OR_REPLACEMENT_FINDER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_new_source_or_replacement_finder.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_NEW_SOURCE_OR_REPLACEMENT_FINDER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_new_source_or_replacement_finder.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_NEW_SOURCE_CANDIDATE_REVIEWER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_new_source_candidate_reviewer.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_NEW_SOURCE_CANDIDATE_REVIEWER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_new_source_candidate_reviewer.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SOURCE_CANDIDATE_POOL_EXPANDER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_source_candidate_pool_expander.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SOURCE_CANDIDATE_POOL_EXPANDER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_source_candidate_pool_expander.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_LIVE_SOURCE_RESEARCH_EXPANDER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_live_source_research_expander.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_LIVE_SOURCE_RESEARCH_EXPANDER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_live_source_research_expander.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_FOLLOWUP_LIVE_SOURCE_RESEARCH_EXPANDER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_followup_live_source_research_expander.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_FOLLOWUP_LIVE_SOURCE_RESEARCH_EXPANDER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_followup_live_source_research_expander.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_expanded_source_candidate_reviewer.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_expanded_source_candidate_reviewer.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_FOLLOWUP_SOURCE_CANDIDATE_EXPANDER = (
    SCRIPT_DIR / "global_commander_external_nonpayoff_followup_source_candidate_expander.py"
)
GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_FOLLOWUP_SOURCE_CANDIDATE_EXPANDER_TEST = (
    SCRIPT_DIR / "test_global_commander_external_nonpayoff_followup_source_candidate_expander.py"
)
README = REPO_ROOT / "docs/hermes-analysis/README.md"

CONTRACT_MATRIX_JSON = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json"
)
CONTRACT_MATRIX_MD = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.md"
)
ARTIFACT_CONTRACT_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260629_v615_mana_engine_current.md"
)
PROMOTION_DECISION_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.md"
)
CUT_METHODOLOGY_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/lorehold_cut_methodology_reaudit_20260629.md"
)
GLOBAL_COMMANDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_deck_contract_audit_20260701_post_scope_legalities.md"
)
GLOBAL_COMMANDER_MATRIX_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_strategy_matrix_20260701_current.md"
)
GLOBAL_COMMANDER_CORE_ROLE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_core_role_audit_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_mana_base_profile_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_LAND_FLOOR_POLICY_BUILDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_land_floor_policy_builder_20260706_current.md"
)
GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_SYNTHESIZER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_land_floor_package_synthesizer_20260706_deck612.md"
)
GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.md"
)
GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_learning_priority_audit_20260706_engine_axis_exhaustion_current.md"
)
GLOBAL_COMMANDER_LEARNING_PRIORITY_RAMP_AXIS_EXHAUSTION_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_learning_priority_audit_20260706_ramp_axis_exhaustion_current.md"
)
GLOBAL_COMMANDER_CROSS_COMMANDER_ROLE_AXIS_LEARNING_PIVOT_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_cross_commander_role_axis_learning_pivot_20260706_engine_axis_exhaustion_current.md"
)
GLOBAL_COMMANDER_CROSS_COMMANDER_ROLE_AXIS_RAMP_EXHAUSTION_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_cross_commander_role_axis_learning_pivot_20260706_ramp_axis_exhaustion_current.md"
)
GLOBAL_COMMANDER_ROLE_AXIS_POLICY_BUILDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_role_axis_policy_builder_20260706_post_engine_axis_exhaustion_current.md"
)
GLOBAL_COMMANDER_ROLE_AXIS_POLICY_BUILDER_POST_RAMP_EXHAUSTION_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_role_axis_policy_builder_20260706_post_ramp_axis_exhaustion_current.md"
)
GLOBAL_COMMANDER_ENGINE_AXIS_NONLAND_CUT_POLICY_MODEL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_engine_axis_nonland_cut_policy_model_20260706_current.md"
)
GLOBAL_COMMANDER_RAMP_AXIS_NONLAND_CUT_POLICY_MODEL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_ramp_axis_nonland_cut_policy_model_20260706_current.md"
)
GLOBAL_COMMANDER_RAMP_CUT_USAGE_SAME_LANE_PROOF_SCOUT_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_ramp_cut_usage_same_lane_proof_scout_20260706_current.md"
)
GLOBAL_COMMANDER_RAMP_CUT_FOLLOWUP_ROUTER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_ramp_cut_followup_router_20260706_current.md"
)
GLOBAL_COMMANDER_RAMP_CUT_TRACE_REPLACEMENT_GATE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_ramp_cut_trace_replacement_gate_20260706_current.md"
)
GLOBAL_COMMANDER_RAMP_CUT_FORCED_ACCESS_TRACE_GENERATOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_ramp_cut_forced_access_trace_generator_20260706_current.md"
)
GLOBAL_COMMANDER_RAMP_CUT_FORCED_RECOVERY_ROUTER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_ramp_cut_forced_recovery_router_20260706_current.md"
)
GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_TRACE_GENERATOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_ramp_alternative_cut_trace_generator_20260706_current.md"
)
GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_FORCED_ACCESS_TRACE_GENERATOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_ramp_alternative_cut_forced_access_trace_generator_20260706_current.md"
)
GLOBAL_COMMANDER_RAMP_AXIS_EXHAUSTION_ROUTER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_ramp_axis_exhaustion_router_20260706_current.md"
)
GLOBAL_COMMANDER_ENGINE_CUT_USAGE_SAME_LANE_PROOF_SCOUT_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_engine_cut_usage_same_lane_proof_scout_20260706_current.md"
)
GLOBAL_COMMANDER_ENGINE_CUT_FOLLOWUP_ROUTER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_engine_cut_followup_router_20260706_current.md"
)
GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_GATE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_engine_cut_trace_replacement_gate_20260706_current.md"
)
GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_REVIEWER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_engine_cut_trace_replacement_reviewer_20260706_current.md"
)
GLOBAL_COMMANDER_ENGINE_EXACT_REPLACEMENT_OR_NEW_CUT_FINDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_engine_exact_replacement_or_new_cut_finder_20260706_current.md"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_SOURCE_EXPANDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_exact_artifact_engine_source_expander_20260706_current.md"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_CANDIDATE_REVIEWER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_exact_artifact_engine_candidate_reviewer_20260706_current.md"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ORACLE_BACKFILL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_exact_artifact_oracle_backfill_20260706_current.md"
)
GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_ADD_CUT_PAIR_MODEL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_exact_artifact_engine_add_cut_pair_model_20260706_current.md"
)
GLOBAL_COMMANDER_EXACT_ARTIFACT_TYPE_CONVERSION_SOURCE_LANE_EXPANDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_exact_artifact_type_conversion_source_lane_expander_20260706_current.md"
)
GLOBAL_COMMANDER_BIOTRANSFERENCE_PROTECTION_PIVOT_ROUTER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_biotransference_protection_pivot_router_20260706_current.md"
)
GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_nonland_top_pair.md"
)
GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_MATERIALIZER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260706_land_floor_deck612_package.md"
)
GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_CHAIN_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_chain_audit_20260706_land_floor_deck612_package.md"
)
GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_STRATEGY_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260706_land_floor_deck612_package.md"
)
GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_STRATEGY_LOREHOLD_PROFILE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260706_land_floor_deck612_package_lorehold_profile.md"
)
GLOBAL_COMMANDER_CANDIDATE_BATTLE_PROBE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_battle_probe_audit_20260705_kaalia_nonland_floor_dynamic_target.md"
)
GLOBAL_COMMANDER_BATTLE_FEEDBACK_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_battle_feedback_model_20260705_current.md"
)
GLOBAL_COMMANDER_CANDIDATE_PACKAGE_CHAIN_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_chain_audit_20260705_kaalia_removal_floor_step5.md"
)
GLOBAL_COMMANDER_CANDIDATE_PACKAGE_STRATEGY_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5.md"
)
GLOBAL_COMMANDER_PROFILE_BLOCKER_REPAIR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_profile_blocker_repair_plan_20260705_kaalia_removal_floor_step5.md"
)
GLOBAL_COMMANDER_PROFILE_REPAIR_CANDIDATE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5.md"
)
GLOBAL_COMMANDER_PAYOFF_SOURCE_LANE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_payoff_source_lane_expander_20260705_kaalia_removal_floor_step5.md"
)
GLOBAL_COMMANDER_PAYOFF_PACKAGE_SYNTHESIS_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_payoff_package_synthesizer_20260705_kaalia_removal_floor_step5.md"
)
GLOBAL_COMMANDER_CUT_SOURCE_LANE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.md"
)
GLOBAL_COMMANDER_VALUE_SAFE_STAGE_SPLITTER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_value_safe_stage_splitter_20260705_kaalia_removal_floor_step5.md"
)
GLOBAL_COMMANDER_VALUE_SAFE_STAGE1_MATERIALIZER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1.md"
)
GLOBAL_COMMANDER_VALUE_SAFE_STAGE1_CHAIN_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1.md"
)
GLOBAL_COMMANDER_VALUE_SAFE_STAGE1_STRATEGY_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1.md"
)
GLOBAL_COMMANDER_PACKAGE_SCOPE_REDUCER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_stage2.md"
)
GLOBAL_COMMANDER_REPAIR_SCOPE1_MATERIALIZER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_REPAIR_SCOPE1_CHAIN_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_REPAIR_SCOPE1_STRATEGY_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_PROFILE_BLOCKER_REPAIR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_profile_blocker_repair_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_PROFILE_REPAIR_CANDIDATE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_profile_repair_candidate_model_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_PAYOFF_SOURCE_LANE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_payoff_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_PAYOFF_PACKAGE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_CUT_SOURCE_LANE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_PACKAGE_SCOPE_REDUCER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_STAGE_ONLY_CUT_EVIDENCE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_stage_only_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_CONTEXTUAL_STAGE_CUT_EVIDENCE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_CONTEXTUAL_USAGE_TRACE_SCOUT_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_scout_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_CONTEXTUAL_USAGE_TRACE_GENERATOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_CONTEXTUAL_USAGE_TRACE_REVIEWER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_REPLACEMENT_MODEL_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_replacement_model_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_NEW_CUT_SOURCE_LANE_TRACE_COLLECTOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_FORCED_CUT_ACCESS_TRACE_GENERATOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_forced_cut_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_POST_FORCED_CUT_SOURCE_LANE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md"
)
GLOBAL_COMMANDER_SCOPE1_POST_FORCED_PACKAGE_SCOPE_REDUCER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md"
)
GLOBAL_COMMANDER_SCOPE1_POST_FORCED_RECOVERY_SYNTHESIZER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_post_forced_recovery_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_VALUE_SAFE_CUT_SOURCE_MINER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_VALUE_SAFE_CUT_SOURCE_MINER_EXTERNAL_POLICY_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md"
)
GLOBAL_COMMANDER_SCOPE1_CUT_SOURCE_HYPOTHESIS_TRACE_COLLECTOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_CUT_HYPOTHESIS_SAME_LANE_PROOF_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_cut_hypothesis_same_lane_proof_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_CUT_SOURCE_RESEARCH_PLAN_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_cut_source_research_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_REFERENCE_CORPUS_COLLECTOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_reference_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_CORPUS_CUT_POLICY_MAPPER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_corpus_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_PACKAGE_AXIS_BROADENING_PLAN_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_package_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_PACKAGE_RESYNTHESIZER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_package_resynthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_ADD_SOURCE_LANE_EXPANDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_add_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_PACKAGE_SOURCE_SYNTHESIZER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_CUT_PAIR_COLLECTOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_CUT_EVIDENCE_PLAN_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_STAGE_CUT_TRACE_COLLECTOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_stage_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_USED_CUT_RECOVERY_ROUTER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_used_cut_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_NEW_CUT_SOURCE_MINER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_new_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_SAME_LANE_CUT_AXIS_BROADENING_PLAN_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_cut_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_CORPUS_COLLECTOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_same_lane_cut_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_POLICY_MAPPER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_same_lane_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_DISCOVERER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_same_lane_source_candidate_discoverer_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_REVIEWER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_same_lane_source_candidate_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_SEEDED_CUT_TRACE_COLLECTOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_seeded_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_SEEDED_FORCE_ACCESS_TRACE_GENERATOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_seeded_force_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_CURRENT_DB_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_current_db.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_current_deck_negative_review_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_NEW_SOURCE_OR_REPLACEMENT_FINDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_new_source_or_replacement_finder_20260706_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_NEW_SOURCE_CANDIDATE_REVIEWER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_new_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_NEW_SOURCES_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_NEW_SOURCES_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SOURCE_CANDIDATE_POOL_EXPANDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_source_candidate_pool_expander_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SOURCE_CANDIDATE_POOL_EXPANDER_FOLLOWUP_CUMULATIVE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_source_candidate_pool_expander_20260706_kaalia_value_safe_stage1_repair_scope1_followup_cumulative.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_LIVE_SOURCE_RESEARCH_EXPANDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_live_source_research_expander_20260706_kaalia_value_safe_stage1_repair_scope1.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_LIVE_RESEARCH_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_live_research.md"
)
GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_EXPANDED_SOURCES_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md"
)
GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_LIVE_RESEARCH_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_live_research.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_LIVE_RESEARCH_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_live_research.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR_LIVE_RESEARCH_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_current_deck_negative_review_collector_20260706_kaalia_value_safe_stage1_live_research.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_MANUAL_NEGATIVE_TRACE_REVIEWER_LIVE_RESEARCH_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_manual_negative_trace_reviewer_20260706_kaalia_value_safe_stage1_live_research.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_FOLLOWUP_LIVE_SOURCE_RESEARCH_EXPANDER_AFTER_MANUAL_TRACE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_followup_live_source_research_expander_20260706_kaalia_value_safe_stage1_after_manual_trace.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_FOLLOWUP_LIVE_AFTER_MANUAL_TRACE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_followup_live_after_manual_trace.md"
)
GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_FOLLOWUP_LIVE_AFTER_MANUAL_TRACE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_followup_live_after_manual_trace.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_FOLLOWUP_LIVE_AFTER_MANUAL_TRACE_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_followup_live_after_manual_trace.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_EXPANDED_SOURCES_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR_EXPANDED_SOURCES_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_current_deck_negative_review_collector_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_FOLLOWUP_SOURCE_CANDIDATE_EXPANDER_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_followup_source_candidate_expander_20260706_kaalia_value_safe_stage1_repair_scope1_after_mana_vault.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_FOLLOWUP_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md"
)
GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_FOLLOWUP_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md"
)
GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_FOLLOWUP_REPORT = (
    REPO_ROOT
    / "docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md"
)

REQUIRED_FOCUS_CARDS = {
    "Aetherflux Reservoir",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Mana Vault",
    "Molecule Man",
    "Sensei's Divining Top",
    "Scroll Rack",
}

HISTORICAL_BLOCKED_SURFACES = {
    SCRIPT_DIR / "build_optimized_deck.py": "status=historical_disabled",
    SCRIPT_DIR / "universal_optimizer.py": "legacy_deprecated_not_authorized_for_handoff",
}

VOLATILE_HISTORICAL_REPORTS = {
    GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_REPORT: {
        "reason": "candidate copy snapshot depends on ignored local Hermes DB artifacts",
        "patterns": [
            "Global Commander Candidate Copy Materializer",
            "candidate_materialized_structure_ready_next_gate_closed",
            "promotion_allowed: `false`",
            "allow_battle_gate_now: `false`",
        ],
    },
    GLOBAL_COMMANDER_CANDIDATE_BATTLE_PROBE_REPORT: {
        "reason": "battle probe snapshot depends on ignored replay artifacts",
        "patterns": [
            "battle_probe_blocks_promotion",
            "base_wr: `66.7`",
            "candidate_wr: `33.3`",
            "candidate_underperformed_base_probe",
            "added_cards_not_exercised_in_replay_events",
            "stale_lorehold_mentions: `0`",
        ],
    },
    GLOBAL_COMMANDER_BATTLE_FEEDBACK_REPORT: {
        "reason": "feedback snapshot depends on prior ignored battle probe reports",
        "patterns": [
            "Global Commander Battle Feedback Model",
            "pair_blocked_by_failed_gate",
            "pair_needs_exposure_replay_before_gate",
            "block_pair_until_new_source_lane_or_cut",
            "Feed the Swarm",
            "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            "Archaeomancer's Map",
            "ready_pair_count: `0`",
        ],
    },
    GLOBAL_COMMANDER_CANDIDATE_PACKAGE_CHAIN_REPORT: {
        "reason": "package chain snapshot depends on ignored candidate-copy lineage artifacts",
        "patterns": [
            "Global Commander Candidate Package Chain Audit",
            "core_floor_repaired: `true`",
            "battle_gate_allowed_now: `false`",
            "promotion_allowed: `false`",
            "Path to Exile",
            "Feed the Swarm",
            "Swords to Plowshares",
            "Rakdos Charm",
            "Terminate",
            "run_commander_specific_strategy_matrix_for_package_before_battle",
        ],
    },
    GLOBAL_COMMANDER_VALUE_SAFE_STAGE1_MATERIALIZER_REPORT: {
        "reason": "value-safe stage candidate copy depends on ignored local Hermes DB artifacts",
        "patterns": [
            "Global Commander Candidate Copy Materializer",
            "candidate_materialized_structure_ready_next_gate_closed",
            "candidate: `8` swap(s)",
            "stage: `1`",
            "source_artifact_type: `global_commander_value_safe_stage_splitter`",
            "source_unchanged: `true`",
            "allow_battle_gate_now: `false`",
            "Arena of Glory",
            "Goldlust Triad",
        ],
    },
    GLOBAL_COMMANDER_VALUE_SAFE_STAGE1_CHAIN_REPORT: {
        "reason": "value-safe stage chain snapshot depends on ignored candidate-copy lineage artifacts",
        "patterns": [
            "Global Commander Candidate Package Chain Audit",
            "status: `blocked`",
            "swap_count: `8`",
            "materializer_chain_pass: `true`",
            "core_floor_repaired: `false`",
            "final_core_floor_not_repaired",
            "package_battle_probe_not_run",
        ],
    },
    GLOBAL_COMMANDER_VALUE_SAFE_STAGE1_STRATEGY_REPORT: {
        "reason": "value-safe stage package strategy matrix depends on ignored candidate DB artifact",
        "patterns": [
            "Global Commander Candidate Package Strategy Matrix",
            "package_strategy_blocks_battle",
            "battle_gate_allowed_now: `false`",
            "package_core_floor_not_repaired",
            "profile_angels_demons_dragons_payoffs_below_target",
            "profile_spot_interaction_below_target",
        ],
    },
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def check_contains(path: Path, patterns: list[str]) -> dict[str, Any]:
    text = read(path)
    missing = [pattern for pattern in patterns if pattern not in text]
    return {
        "path": rel(path),
        "exists": path.exists(),
        "status": "pass" if path.exists() and not missing else "fail",
        "missing": missing,
    }


def check_volatile_historical_report(path: Path, spec: dict[str, Any]) -> dict[str, Any]:
    text = read(path)
    patterns = spec["patterns"]
    missing = [pattern for pattern in patterns if pattern not in text]
    return {
        "path": rel(path),
        "exists": path.exists(),
        "status": "pass" if path.exists() and not missing else "warn",
        "missing": missing,
        "reason": spec["reason"],
    }


def build_audit() -> dict[str, Any]:
    checks: list[dict[str, Any]] = []
    volatile_historical_reports: list[dict[str, Any]] = []
    checks.append(
        check_contains(
            CONTRACT_DOC,
            [
                "Status: `frozen_operating_contract`",
                "Source Hierarchy",
                "Lorehold Promotion Gate",
                "Research-Backed Deck Planning Flow",
                "Lane Order And Deck Overview Contract",
                "Staple Impact Policy",
                "staple_impact_and_role_policy",
                "staple_impact_by_role",
                "battle_cleared_with_cut_methodology_caveat",
                "decks[] + ranked_deck_keys",
                "lorehold_artifact_contract_audit.py",
                "lorehold_promotion_gate_decision_audit.py",
                "candidate_607_v615_mana_engine_v1",
                "Global Commander Rollout - 2026-07-01",
                "Global Commander Core Pivot - 2026-07-05",
                "benchmark/regression deck",
                "global_commander_deck_contract_audit.py",
                "global_commander_strategy_matrix.py",
                "global_commander_core_role_audit.py",
                "global_commander_core_role_audit_20260705_global_goal_hermes_only.md",
                "global_commander_core_repair_hypothesis.py",
                "global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.md",
                "global_commander_mana_base_profile.py",
                "global_commander_mana_base_profile_20260705_global_goal_hermes_only.md",
                "global_commander_named_land_candidate_pool.py",
                "global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.md",
                "global_commander_land_cut_candidate_model.py",
                "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.md",
                "global_commander_nonland_core_candidate_model.py",
                "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.md",
                "Kaalia Angel/Demon/Dragon creatures are blocked",
                "global_commander_learning_priority_audit.py",
                "global_commander_learning_priority_audit_20260706_engine_axis_exhaustion_current.md",
                "pivot_to_cross_commander_role_axis_learning_after_engine_axis_exhaustion",
                "role_axis_exhausted_requires_global_learning_pivot",
                "pivot_to_cross_commander_role_axis_learning_after_ramp_axis_exhaustion",
                "global_commander_learning_priority_audit_20260706_ramp_axis_exhaustion_current.md",
                "global_commander_cross_commander_role_axis_learning_pivot_20260706_ramp_axis_exhaustion_current.md",
                "global_commander_role_axis_policy_builder_20260706_post_ramp_axis_exhaustion_current.md",
                "calibrate_land_floor_policy_before_candidate_copy",
                "global_commander_land_floor_policy_builder.py",
                "global_commander_land_floor_package_synthesizer.py",
                "global_commander_land_floor_policy_builder_20260706_current.md",
                "run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane",
                "global_commander_land_floor_package_synthesizer_20260706_deck612.md",
                "global_commander_candidate_copy_materializer_20260706_land_floor_deck612_package.md",
                "global_commander_candidate_package_chain_audit_20260706_land_floor_deck612_package.md",
                "global_commander_candidate_package_strategy_matrix_20260706_land_floor_deck612_package.md",
                "global_commander_candidate_package_strategy_matrix_20260706_land_floor_deck612_package_lorehold_profile.md",
                "commander_profile_not_available",
                "profile_lands_below_target",
                "protected anchor cuts",
                "repair_commander_profile_blockers_before_battle",
                "global_commander_external_exact_artifact_engine_source_expander.py",
                "global_commander_external_exact_artifact_engine_source_expander_20260706_current.md",
                "review_external_exact_artifact_engine_candidates_locally_before_candidate_copy",
                "global_commander_external_exact_artifact_engine_candidate_reviewer.py",
                "global_commander_external_exact_artifact_engine_candidate_reviewer_20260706_current.md",
                "backfill_local_oracle_cache_for_external_exact_engine_seeds_before_add_cut_review",
                "global_commander_external_exact_artifact_oracle_backfill.py",
                "global_commander_external_exact_artifact_oracle_backfill_20260706_current.md",
                "model_external_exact_artifact_engine_add_cut_pairs_before_candidate_copy",
                "global_commander_external_exact_artifact_engine_add_cut_pair_model.py",
                "global_commander_external_exact_artifact_engine_add_cut_pair_model_20260706_current.md",
                "expand_exact_artifact_type_conversion_source_lane_or_keep_biotransference_protected",
                "global_commander_exact_artifact_type_conversion_source_lane_expander.py",
                "global_commander_exact_artifact_type_conversion_source_lane_expander_20260706_current.md",
                "protect_biotransference_and_pivot_to_non_biotransference_engine_cut_or_global_axis",
                "global_commander_biotransference_protection_pivot_router.py",
                "global_commander_biotransference_protection_pivot_router_20260706_current.md",
                "return_to_global_role_axis_learning_priority_after_engine_axis_exhaustion",
                "global_commander_candidate_copy_materializer.py",
                "global_commander_candidate_copy_materializer_20260705_kaalia_nonland_top_pair.md",
                "must reject stale chained sources",
                "Bloodthirster",
                "battle_probe_ready_for_larger_gate",
                "Demonic Tutor",
                "Kinnan, Bonder Prodigy",
                "candidate_underperformed_base_probe",
                "22.2%",
                "do not cut `Birgi`",
                "cross_lane_ramp_cut_requires_same_lane_source_or_gate",
                "Archaeomancer's Map",
                "candidate `33.3%`",
                "global_commander_candidate_battle_probe_audit.py",
                "global_commander_candidate_battle_probe_audit_20260705_kaalia_nonland_floor_dynamic_target.md",
                "global_commander_battle_feedback_model.py",
                "global_commander_battle_feedback_model_20260705_current.md",
                "pair_blocked_by_failed_gate",
                "pair_needs_exposure_replay_before_gate",
                "block_pair_until_new_source_lane_or_cut",
                "blocked_by_global_battle_feedback",
                "blocked_pair_hypotheses",
                "global_commander_candidate_package_chain_audit.py",
                "global_commander_candidate_package_chain_audit_20260705_kaalia_removal_floor_step5.md",
                "core_floor_repaired",
                "run_commander_specific_strategy_matrix_for_package_before_battle",
                "global_commander_candidate_package_strategy_matrix.py",
                "global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5.md",
                "package_strategy_blocks_battle",
                "profile_lands_below_target",
                "profile_angels_demons_dragons_payoffs_below_target",
                "profile_spot_interaction_below_target",
                "attack_window_cut_without_replacement",
                "repair_commander_profile_blockers_before_battle",
                "global_commander_profile_blocker_repair_plan.py",
                "global_commander_profile_blocker_repair_plan_20260705_kaalia_removal_floor_step5.md",
                "profile_blocker_repair_plan_ready",
                "repair_or_restore_commander_attack_window_before_more_interaction",
                "repair_mana_base_to_commander_land_floor",
                "repair_commander_payoff_density_with_legal_source_lanes",
                "finish_spot_interaction_floor_with_same_lane_cut",
                "global_commander_profile_repair_candidate_model.py",
                "global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5.md",
                "profile_repair_candidate_model_blocks_materialization",
                "candidate_copy_allowed_now=false",
                "expand_commander_payoff_source_lane_before_candidate_copy",
                "global_commander_payoff_source_lane_expander.py",
                "global_commander_payoff_source_lane_expander_20260705_kaalia_removal_floor_step5.md",
                "commander_payoff_source_lane_expanded",
                "ready_candidates_cover_shortfall=true",
                "synthesize_commander_payoff_package_before_candidate_copy",
                "global_commander_payoff_package_synthesizer.py",
                "global_commander_payoff_package_synthesizer_20260705_kaalia_removal_floor_step5.md",
                "commander_payoff_package_synthesis_blocks_candidate_copy",
                "insufficient_reviewable_cuts_for_full_profile_package",
                "expand_commander_cut_source_lane_for_full_profile_package",
                "global_commander_cut_source_lane_expander.py",
                "global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.md",
                "commander_cut_source_lane_expanded_stage_split_required",
                "value_safe_cut_shortfall:required_21_ready_18",
                "split_synthesized_package_into_value_safe_stages",
                "global_commander_value_safe_stage_splitter.py",
                "global_commander_value_safe_stage_splitter_20260705_kaalia_removal_floor_step5.md",
                "commander_value_safe_stage_split_ready_for_stage_candidate_copy",
                "full_package_unpaired_adds:required_21_paired_18",
                "materialize_value_safe_stage_1_candidate_copy",
                "global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1.md",
                "global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1.md",
                "global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1.md",
                "candidate_materialized_structure_ready_next_gate_closed",
                "final_core_status=core_role_gap",
                "package_core_floor_not_repaired",
                "repair_commander_profile_blockers_before_battle",
                "allow_chained_source=true",
                "core_removal_floor",
                "reanimation_plan_b",
                "structural staples",
                "value_safe_cut_shortfall:required_7_ready_1",
                "backfill_value_safe_cuts_or_reduce_package_scope",
                "global_commander_package_scope_reducer.py",
                "global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_stage2.md",
                "commander_package_scope_reduced_ready_for_candidate_copy",
                "materialize_reduced_scope_candidate_copy",
                "global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "angels_demons_dragons_payoffs` is only `16`",
                "global_commander_stage_only_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Ornithopter of Paradise",
                "contextual_staple_same_lane_usage_review",
                "collect_stage_only_cut_evidence_before_value_safe_reclassification",
                "global_commander_contextual_stage_cut_evidence_collector.py",
                "global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "contextual_stage_cut_evidence_collected_no_value_safe_reclassification",
                "collect_usage_or_trace_evidence_for_contextual_stage_cuts",
                "global_commander_contextual_usage_trace_scout.py",
                "global_commander_contextual_usage_trace_scout_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "contextual_usage_trace_scout_no_current_trace_evidence",
                "generate_or_import_current_scope_usage_trace_before_reclassification",
                "global_commander_contextual_usage_trace_generator.py",
                "global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "global_commander_contextual_usage_trace_reviewer.py",
                "global_commander_contextual_usage_trace_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "contextual_usage_trace_review_blocks_value_safe_reclassification",
                "find_new_cut_source_lane_or_same_lane_replacement_proof_before_candidate_copy",
                "global_commander_same_lane_replacement_model.py",
                "global_commander_same_lane_replacement_model_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_replacement_model_routes_to_new_cut_source_lane",
                "collect_new_cut_source_lane_evidence_after_contextual_usage_block",
                "global_commander_new_cut_source_lane_trace_collector.py",
                "global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "new_cut_source_lane_trace_blocks_used_remaining_cuts",
                "force_access_or_expand_cut_source_lane_for_unresolved_remaining_cuts",
                "global_commander_forced_cut_access_trace_generator.py",
                "global_commander_forced_cut_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "forced_cut_access_trace_blocks_used_unresolved_cuts",
                "expand_cut_source_lane_after_forced_access_blocks_current_unresolved_cuts",
                "global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md",
                "global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md",
                "forced_cut_access_blocks_unresolved_cut_reclassification:3",
                "synthesize_new_value_safe_cut_source_or_smaller_package_after_forced_access_block",
                "global_commander_post_forced_recovery_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "post_forced_recovery_blocks_candidate_copy_needs_new_cut_source",
                "mine_new_value_safe_cut_source_before_package_resynthesis",
                "global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "value_safe_cut_source_hypotheses_ready_for_trace",
                "collect_usage_trace_for_new_cut_source_hypotheses",
                "global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "cut_source_hypothesis_trace_blocks_used_hypotheses",
                "mine_more_hypotheses_or_build_same_lane_proof",
                "global_commander_cut_hypothesis_same_lane_proof.py",
                "global_commander_cut_hypothesis_same_lane_proof_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "cut_hypothesis_same_lane_proof_routes_to_more_mining",
                "mine_more_hypotheses_or_external_cut_source_research",
                "global_commander_external_cut_source_research_plan.py",
                "global_commander_external_cut_source_research_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_cut_source_research_plan_ready_no_deck_action",
                "collect_external_commander_reference_corpus_for_cut_candidates",
                "global_commander_external_reference_corpus_collector.py",
                "global_commander_external_reference_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_reference_corpus_collected_no_cut_permission",
                "map_external_corpus_to_cut_policy_before_rerun_miner",
                "global_commander_external_corpus_cut_policy_mapper.py",
                "global_commander_external_corpus_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_corpus_cut_policy_blocks_current_hypotheses",
                "rerun_value_safe_cut_source_miner_with_external_policy_exclusions",
                "global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md",
                "external_policy_exclusion_count=8",
                "broaden_commander_package_axis_or_external_cut_research",
                "global_commander_package_axis_broadening_plan.py",
                "global_commander_package_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md",
                "commander_package_axis_broadening_plan_ready_no_deck_action",
                "package_axis_mismatch_with_exhausted_cut_lanes",
                "resynthesize_package_with_same_lane_axis_requirements",
                "global_commander_same_lane_package_resynthesizer.py",
                "global_commander_same_lane_package_resynthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes",
                "expand_same_lane_add_source_lanes_for_target_cut_roles",
                "global_commander_same_lane_add_source_lane_expander.py",
                "global_commander_same_lane_add_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_add_source_lanes_expanded_no_deck_action",
                "resynthesize_same_lane_package_from_source_lanes_before_cut_pairing",
                "global_commander_same_lane_package_source_synthesizer.py",
                "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_source_package_synthesized_no_cut_pairs",
                "collect_value_safe_same_lane_cut_pairs_for_resynthesized_package",
                "global_commander_same_lane_cut_pair_collector.py",
                "global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_cut_pair_collection_blocks_candidate_copy",
                "collect_more_same_lane_cut_evidence_or_broaden_cut_source_lanes",
                "global_commander_same_lane_cut_evidence_plan.py",
                "global_commander_same_lane_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_cut_evidence_plan_ready_no_deck_action",
                "collect_trace_or_external_evidence_for_same_lane_stage_only_cuts",
                "global_commander_same_lane_stage_cut_trace_collector.py",
                "global_commander_same_lane_stage_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_stage_cut_trace_collection_blocks_used_cuts",
                "build_same_lane_replacement_or_find_new_cut_source_for_used_stage_cuts",
                "global_commander_same_lane_used_cut_recovery_router.py",
                "global_commander_same_lane_used_cut_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_used_cut_recovery_routes_to_new_cut_source",
                "mine_or_research_new_same_lane_cut_source_before_candidate_copy",
                "global_commander_same_lane_new_cut_source_miner.py",
                "global_commander_same_lane_new_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_new_cut_source_mining_exhausted_current_deck",
                "broaden_same_lane_cut_research_or_package_axis_before_candidate_copy",
                "global_commander_same_lane_cut_axis_broadening_plan.py",
                "global_commander_same_lane_cut_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_cut_axis_broadening_plan_ready_no_deck_action",
                "collect_external_nonpayoff_same_lane_cut_corpus_for_exhausted_roles",
                "global_commander_external_nonpayoff_same_lane_cut_corpus_collector.py",
                "global_commander_external_nonpayoff_same_lane_cut_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_same_lane_corpus_collected_no_cut_permission",
                "map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery",
                "global_commander_external_nonpayoff_same_lane_cut_policy_mapper.py",
                "global_commander_external_nonpayoff_same_lane_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_same_lane_policy_ready_no_cut_permission",
                "discover_external_nonpayoff_same_lane_source_candidates_before_miner",
                "global_commander_external_nonpayoff_same_lane_source_candidate_discoverer.py",
                "global_commander_external_nonpayoff_same_lane_source_candidate_discoverer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission",
                "review_external_nonpayoff_same_lane_source_candidates_locally_before_miner",
                "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer.py",
                "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_same_lane_source_candidates_reviewed_miner_seed_ready_no_deck_action",
                "rerun_same_lane_cut_source_miner_with_reviewed_external_nonpayoff_candidates",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner.py",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "reviewed_external_seeded_cut_source_hypotheses_ready_for_trace",
                "collect_trace_for_reviewed_external_seeded_cut_source_hypotheses",
                "global_commander_reviewed_external_seeded_cut_trace_collector.py",
                "global_commander_reviewed_external_seeded_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "reviewed_external_seeded_cut_trace_needs_force_access",
                "force_access_or_expand_replay_window_for_seeded_hypotheses",
                "global_commander_reviewed_external_seeded_force_access_trace_generator.py",
                "global_commander_reviewed_external_seeded_force_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "reviewed_external_seeded_forced_access_blocks_absent_hypotheses",
                "rerun_seeded_cut_source_miner_against_current_evaluation_db",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_current_db.md",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy",
                "global_commander_external_nonpayoff_seed_exhaustion_recovery_router.py",
                "global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review",
                "collect_current_deck_negative_review_for_external_nonpayoff_candidates",
                "global_commander_external_nonpayoff_current_deck_negative_review_collector.py",
                "global_commander_external_nonpayoff_current_deck_negative_review_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_current_deck_negative_review_blocks_used_candidates",
                "find_new_external_source_or_explicit_same_lane_replacement_proof",
                "global_commander_external_nonpayoff_new_source_or_replacement_finder.py",
                "global_commander_external_nonpayoff_new_source_or_replacement_finder_20260706_kaalia_value_safe_stage1_repair_scope1.md",
                "new_external_source_candidates_ready_for_local_review",
                "review_new_external_nonpayoff_source_candidates_locally_before_seeded_miner",
                "global_commander_external_nonpayoff_new_source_candidate_reviewer.py",
                "global_commander_external_nonpayoff_new_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1.md",
                "new_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "rerun_seeded_cut_source_miner_with_new_reviewed_external_nonpayoff_sources",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "blocked_recycled_seeded_cut_source_count=47",
                "global_commander_external_nonpayoff_source_candidate_pool_expander.py",
                "global_commander_external_nonpayoff_source_candidate_pool_expander_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md",
                "external_nonpayoff_source_candidate_pool_expanded_ready_for_local_review",
                "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
                "global_commander_external_nonpayoff_expanded_source_candidate_reviewer.py",
                "global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md",
                "expanded_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md",
                "global_commander_external_nonpayoff_current_deck_negative_review_collector_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md",
                "external_current_deck_negative_review_blocks_used_candidates",
                "usage_blocked_candidate_count=1",
                "global_commander_external_nonpayoff_followup_source_candidate_expander.py",
                "global_commander_external_nonpayoff_followup_source_candidate_expander_20260706_kaalia_value_safe_stage1_repair_scope1_after_mana_vault.md",
                "external_nonpayoff_followup_source_candidate_pool_expanded_ready_for_local_review",
                "cumulative_previous_candidate_name_count=55",
                "followup_ready_for_review_count=34",
                "global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md",
                "miner_source_seed_allowed_count=34",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md",
                "reviewed_seed_count=34",
                "global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md",
                "expand_external_nonpayoff_source_candidate_pool",
                "battle_gate_allowed_now",
                "Path to Exile",
                "Terminate",
                "33.3%",
                "66.7%",
                "five Commander",
                "brackets `1..5`",
                "Game Changer budgets",
            ],
        )
    )
    checks.append(
        check_contains(
            SUPPORT_FILE,
            [
                "commanderDeckbuildingContractVersion",
                "commanderDeckPlanningFlowVersion",
                "commanderDeckPlanningFlow",
                "commanderDeckPlanningLaneOrder",
                "commanderDeckOverviewRequiredFields",
                "commanderStapleImpactPolicyDiagnostics",
                "buildCommanderDeckbuildingContractDiagnostics",
                "ready_for_battle_gate",
            ],
        )
    )
    checks.append(
        check_contains(
            REFERENCE_PROFILE_SUPPORT_FILE,
            [
                "kaaliaReferenceCommanderName",
                "buildKaaliaReferenceProfilePayload",
                "isKaaliaCommanderReferenceCandidate",
                "non_angel_demon_dragon_haymaker_as_kaalia_payoff",
                "haste_and_protection_for_attack_window",
            ],
        )
    )
    checks.append(
        check_contains(
            STAPLE_POLICY_FILE,
            [
                "commanderStapleImpactPolicyVersion",
                "commanderStapleImpactPolicyDiagnostics",
                "commanderStapleWeaknessMultiplier",
                "inclusionRate",
                "structural_foundation",
                "generic_or_low_context_signal",
            ],
        )
    )
    checks.append(
        check_contains(
            REBUILD_GUIDED_SERVICE,
            [
                "rebuildGuidedEdhrecTopCardWeight",
                "card.inclusionRate * 20",
            ],
        )
    )
    checks.append(
        check_contains(
            GENERATE_ROUTE,
            [
                "commander_deckbuilding_contract_support.dart",
                "'deckbuilding_contract': deckbuildingContractDiagnostics",
            ],
        )
    )
    checks.append(
        check_contains(
            SUPPORT_TEST,
            [
                "ready_for_battle_gate",
                "reference_lanes_missing",
                "planning_flow",
                "staple_impact_and_role_policy",
                "staple_impact_by_role",
                "lane_balanced_cuts_and_anchor_protection",
            ],
        )
    )
    checks.append(
        check_contains(
            VARIANT_MATRIX,
            ["lorehold_variant_strategy_matrix_20260629_deckbuilding_contract"],
        )
    )
    checks.append(
        check_contains(
            VARIANT_GATE,
            [
                "lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json",
                *sorted(REQUIRED_FOCUS_CARDS),
            ],
        )
    )
    checks.append(
        check_contains(
            ARTIFACT_CONTRACT_AUDIT,
            [
                "strategy_matrix_current_v1",
                "strategy_matrix_legacy_ranked_decks_v0",
                "ready_for_real_deck_change",
            ],
        )
    )
    checks.append(
        check_contains(
            PROMOTION_DECISION_AUDIT,
            [
                "BASELINE_KEY = \"deck_607\"",
                "CHALLENGER_KEYS = (\"deck_614\", \"deck_615\")",
                "ready_for_real_deck_change",
                "keep_protected_baseline",
            ],
        )
    )
    checks.append(
        check_contains(
            README,
            [
                "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md",
                "deckbuilding_contract_surface_audit.py",
                "lorehold_artifact_contract_audit.py",
                "lorehold_promotion_gate_decision_audit.py",
                "global_commander_deck_contract_audit.py",
                "global_commander_strategy_matrix.py",
                "global_commander_deck_contract_audit_20260701_post_scope_legalities.md",
                "global_commander_strategy_matrix_20260701_current.md",
                "global_commander_deck_contract_audit_20260705_global_core_pivot_hermes_only.md",
                "global_commander_strategy_matrix_20260705_global_core_pivot_hermes_only.md",
                "global_commander_core_repair_hypothesis.py",
                "global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.md",
                "global_commander_mana_base_profile.py",
                "global_commander_mana_base_profile_20260705_global_goal_hermes_only.md",
                "global_commander_named_land_candidate_pool.py",
                "global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.md",
                "global_commander_land_cut_candidate_model.py",
                "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.md",
                "global_commander_nonland_core_candidate_model.py",
                "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.md",
                "Angel/Demon/Dragon ficam bloqueadas",
                "global_commander_candidate_copy_materializer.py",
                "global_commander_candidate_copy_materializer_20260705_kaalia_nonland_top_pair.md",
                "fonte encadeada/stale",
                "Bloodthirster",
                "battle_probe_ready_for_larger_gate",
                "Demonic Tutor",
                "Kinnan, Bonder Prodigy",
                "candidate_underperformed_base_probe",
                "22.2%",
                "corte de `Birgi` esta errado",
                "cross_lane_ramp_cut_requires_same_lane_source_or_gate",
                "Archaeomancer's Map",
                "33.3%",
                "global_commander_candidate_battle_probe_audit.py",
                "global_commander_candidate_battle_probe_audit_20260705_kaalia_nonland_floor_dynamic_target.md",
                "candidato `33.3%` vs",
                "nenhuma das cinco remocoes adicionadas foi exercida",
                "global_commander_battle_feedback_model.py",
                "global_commander_battle_feedback_model_20260705_current.md",
                "pair_blocked_by_failed_gate",
                "pair_needs_exposure_replay_before_gate",
                "block_pair_until_new_source_lane_or_cut",
                "blocked_by_global_battle_feedback",
                "blocked_pair_hypotheses",
                "global_commander_candidate_package_chain_audit.py",
                "global_commander_candidate_package_chain_audit_20260705_kaalia_removal_floor_step5.md",
                "core_floor_repaired",
                "run_commander_specific_strategy_matrix_for_package_before_battle",
                "global_commander_candidate_package_strategy_matrix.py",
                "global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5.md",
                "package_strategy_blocks_battle",
                "profile_lands_below_target",
                "profile_angels_demons_dragons_payoffs_below_target",
                "profile_spot_interaction_below_target",
                "attack_window_cut_without_replacement",
                "repair_commander_profile_blockers_before_battle",
                "global_commander_profile_blocker_repair_plan.py",
                "global_commander_profile_blocker_repair_plan_20260705_kaalia_removal_floor_step5.md",
                "repair_or_restore_commander_attack_window_before_more_interaction",
                "repair_mana_base_to_commander_land_floor",
                "repair_commander_payoff_density_with_legal_source_lanes",
                "finish_spot_interaction_floor_with_same_lane_cut",
                "global_commander_profile_repair_candidate_model.py",
                "global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5.md",
                "profile_repair_candidate_model_blocks_materialization",
                "candidate_copy_allowed_now=false",
                "expand_commander_payoff_source_lane_before_candidate_copy",
                "global_commander_payoff_source_lane_expander.py",
                "global_commander_payoff_source_lane_expander_20260705_kaalia_removal_floor_step5.md",
                "commander_payoff_source_lane_expanded",
                "synthesize_commander_payoff_package_before_candidate_copy",
                "global_commander_payoff_package_synthesizer.py",
                "global_commander_payoff_package_synthesizer_20260705_kaalia_removal_floor_step5.md",
                "commander_payoff_package_synthesis_blocks_candidate_copy",
                "expand_commander_cut_source_lane_for_full_profile_package",
                "global_commander_cut_source_lane_expander.py",
                "global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.md",
                "commander_cut_source_lane_expanded_stage_split_required",
                "split_synthesized_package_into_value_safe_stages",
                "global_commander_value_safe_stage_splitter.py",
                "global_commander_value_safe_stage_splitter_20260705_kaalia_removal_floor_step5.md",
                "commander_value_safe_stage_split_ready_for_stage_candidate_copy",
                "materialize_value_safe_stage_1_candidate_copy",
                "global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1.md",
                "global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1.md",
                "global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1.md",
                "candidate_materialized_structure_ready_next_gate_closed",
                "final_core_status=core_role_gap",
                "package_core_floor_not_repaired",
                "repair_commander_profile_blockers_before_battle",
                "allow_chained_source=true",
                "core_removal_floor",
                "reanimation_plan_b",
                "value_safe_cut_shortfall:required_7_ready_1",
                "backfill_value_safe_cuts_or_reduce_package_scope",
                "global_commander_package_scope_reducer.py",
                "global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_stage2.md",
                "commander_package_scope_reduced_ready_for_candidate_copy",
                "materialize_reduced_scope_candidate_copy",
                "global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "angels_demons_dragons_payoffs` segue `16`",
                "global_commander_stage_only_cut_evidence_plan.py",
                "global_commander_stage_only_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Ornithopter of Paradise",
                "contextual_staple_same_lane_usage_review",
                "collect_stage_only_cut_evidence_before_value_safe_reclassification",
                "global_commander_same_lane_replacement_model.py",
                "Incidental role overlap",
                "new cut-source-lane evidence pass",
                "global_commander_new_cut_source_lane_trace_collector.py",
                "force_access_or_expand_cut_source_lane_for_unresolved_remaining_cuts",
                "global_commander_forced_cut_access_trace_generator.py",
                "evaluation target atual",
                "expand_cut_source_lane_after_forced_access_blocks_current_unresolved_cuts",
                "global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md",
                "global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md",
                "forced_usage_blocked_count=3",
                "synthesize_new_value_safe_cut_source_or_smaller_package_after_forced_access_block",
                "global_commander_post_forced_recovery_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "mine_new_value_safe_cut_source_before_package_resynthesis",
                "global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "collect_usage_trace_for_new_cut_source_hypotheses",
                "global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "usage_blocked_hypothesis_count=6",
                "mine_more_hypotheses_or_build_same_lane_proof",
                "global_commander_cut_hypothesis_same_lane_proof_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "explicit_same_lane_route_count=0",
                "incidental_role_overlap_count=9",
                "mine_more_hypotheses_or_external_cut_source_research",
                "global_commander_external_cut_source_research_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_cut_source_research_plan_ready_no_deck_action",
                "external_source_count=6",
                "collect_external_commander_reference_corpus_for_cut_candidates",
                "global_commander_external_reference_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_reference_corpus_collected_no_cut_permission",
                "corpus_present_count=3",
                "corpus_absent_count=5",
                "map_external_corpus_to_cut_policy_before_rerun_miner",
                "global_commander_external_corpus_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_corpus_cut_policy_blocks_current_hypotheses",
                "excluded_from_rerun_miner_count=6",
                "held_for_negative_review_count=2",
                "rerun_miner_allowed_card_count=0",
                "global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md",
                "value_safe_cut_source_mining_blocks_package_resynthesis",
                "external_policy_exclusion_count=8",
                "hypothesis_count=0",
                "global_commander_package_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md",
                "commander_package_axis_broadening_plan_ready_no_deck_action",
                "lane_alignment_status=package_axis_mismatch_with_exhausted_cut_lanes",
                "resynthesize_package_with_same_lane_axis_requirements",
                "global_commander_same_lane_package_resynthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes",
                "held_payoff_add_count=6",
                "expand_same_lane_add_source_lanes_for_target_cut_roles",
                "global_commander_same_lane_add_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_add_source_lanes_expanded_no_deck_action",
                "ready_axis_count=3",
                "resynthesize_same_lane_package_from_source_lanes_before_cut_pairing",
                "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_source_package_synthesized_no_cut_pairs",
                "selected_add_count=8",
                "collect_value_safe_same_lane_cut_pairs_for_resynthesized_package",
                "global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_cut_pair_collection_blocks_candidate_copy",
                "ready_pair_count=0",
                "stage_only_cut_candidate_count=28",
                "collect_more_same_lane_cut_evidence_or_broaden_cut_source_lanes",
                "global_commander_same_lane_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_cut_evidence_plan_ready_no_deck_action",
                "stage_only_cut_evidence_count=28",
                "collect_trace_or_external_evidence_for_same_lane_stage_only_cuts",
                "global_commander_same_lane_stage_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_stage_cut_trace_collection_blocks_used_cuts",
                "usage_blocked_count=19",
                "build_same_lane_replacement_or_find_new_cut_source_for_used_stage_cuts",
                "global_commander_same_lane_used_cut_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_used_cut_recovery_routes_to_new_cut_source",
                "strict_recovery_count=10",
                "mine_or_research_new_same_lane_cut_source_before_candidate_copy",
                "global_commander_same_lane_new_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_new_cut_source_mining_exhausted_current_deck",
                "fresh_same_lane_cut_source_count=0",
                "broaden_same_lane_cut_research_or_package_axis_before_candidate_copy",
                "global_commander_same_lane_cut_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "same_lane_cut_axis_broadening_plan_ready_no_deck_action",
                "collect_external_nonpayoff_same_lane_cut_corpus_for_exhausted_roles",
                "global_commander_external_nonpayoff_same_lane_cut_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_same_lane_corpus_collected_no_cut_permission",
                "map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery",
                "global_commander_external_nonpayoff_same_lane_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_same_lane_policy_ready_no_cut_permission",
                "discover_external_nonpayoff_same_lane_source_candidates_before_miner",
                "global_commander_external_nonpayoff_same_lane_source_candidate_discoverer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission",
                "review_external_nonpayoff_same_lane_source_candidates_locally_before_miner",
                "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_same_lane_source_candidates_reviewed_miner_seed_ready_no_deck_action",
                "rerun_same_lane_cut_source_miner_with_reviewed_external_nonpayoff_candidates",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "reviewed_external_seeded_cut_source_hypotheses_ready_for_trace",
                "collect_trace_for_reviewed_external_seeded_cut_source_hypotheses",
                "global_commander_reviewed_external_seeded_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "reviewed_external_seeded_cut_trace_needs_force_access",
                "force_access_or_expand_replay_window_for_seeded_hypotheses",
                "global_commander_reviewed_external_seeded_force_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "reviewed_external_seeded_forced_access_blocks_absent_hypotheses",
                "rerun_seeded_cut_source_miner_against_current_evaluation_db",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_current_db.md",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy",
                "global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review",
                "collect_current_deck_negative_review_for_external_nonpayoff_candidates",
                "global_commander_external_nonpayoff_current_deck_negative_review_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md",
                "external_current_deck_negative_review_blocks_used_candidates",
                "usage_blocked_candidate_count=5",
                "negative_review_cleared_count=0",
                "find_new_external_source_or_explicit_same_lane_replacement_proof",
                "global_commander_external_nonpayoff_new_source_or_replacement_finder_20260706_kaalia_value_safe_stage1_repair_scope1.md",
                "new_external_source_candidates_ready_for_local_review",
                "new_external_ready_for_review_count=19",
                "review_new_external_nonpayoff_source_candidates_locally_before_seeded_miner",
                "global_commander_external_nonpayoff_new_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1.md",
                "new_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "miner_source_seed_allowed_count=19",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md",
                "scanned_seeded_same_lane_source_count=47",
                "blocked_recycled_seeded_cut_source_count=47",
                "global_commander_external_nonpayoff_source_candidate_pool_expander_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md",
                "external_nonpayoff_source_candidate_pool_expanded_ready_for_local_review",
                "expanded_ready_for_review_count=22",
                "Mana Vault",
                "Mana Crypt",
                "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
                "global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md",
                "expanded_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "miner_source_seed_allowed_count=22",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md",
                "global_commander_external_nonpayoff_current_deck_negative_review_collector_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md",
                "usage_blocked_candidate_count=1",
                "global_commander_external_nonpayoff_followup_source_candidate_expander_20260706_kaalia_value_safe_stage1_repair_scope1_after_mana_vault.md",
                "external_nonpayoff_followup_source_candidate_pool_expanded_ready_for_local_review",
                "cumulative_previous_candidate_name_count=55",
                "followup_ready_for_review_count=34",
                "global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md",
                "miner_source_seed_allowed_count=34",
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md",
                "reviewed_seed_count=34",
                "global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md",
                "expand_external_nonpayoff_source_candidate_pool",
                "battle_gate_allowed_now=false",
                "Path to Exile",
                "Terminate",
            ],
        )
    )
    checks.append(
        {
            "path": rel(CONTRACT_MATRIX_JSON),
            "exists": CONTRACT_MATRIX_JSON.exists(),
            "status": "pass" if CONTRACT_MATRIX_JSON.exists() else "fail",
            "missing": [] if CONTRACT_MATRIX_JSON.exists() else ["matrix_json"],
        }
    )
    checks.append(
        {
            "path": rel(CONTRACT_MATRIX_MD),
            "exists": CONTRACT_MATRIX_MD.exists(),
            "status": "pass" if CONTRACT_MATRIX_MD.exists() else "fail",
            "missing": [] if CONTRACT_MATRIX_MD.exists() else ["matrix_md"],
        }
    )
    checks.append(
        {
            "path": rel(ARTIFACT_CONTRACT_REPORT),
            "exists": ARTIFACT_CONTRACT_REPORT.exists(),
            "status": "pass" if ARTIFACT_CONTRACT_REPORT.exists() else "fail",
            "missing": [] if ARTIFACT_CONTRACT_REPORT.exists() else ["artifact_contract_report"],
        }
    )
    checks.append(
        {
            "path": rel(PROMOTION_DECISION_REPORT),
            "exists": PROMOTION_DECISION_REPORT.exists(),
            "status": "pass" if PROMOTION_DECISION_REPORT.exists() else "fail",
            "missing": [] if PROMOTION_DECISION_REPORT.exists() else ["promotion_decision_report"],
        }
    )
    checks.append(
        check_contains(
            CUT_METHODOLOGY_REPORT,
            [
                "battle_cleared_with_cut_methodology_caveat",
                "The One Ring",
                "Molecule Man",
                "blocked_cross_lane_cut",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_AUDIT,
            [
                "postgres_is_product_truth",
                "lorehold_607_role",
                "registered_pg_variant",
                "test_or_fixture",
                "partner_or_multi_commander_requires_profile",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_MATRIX,
            [
                "global_commander_deck_contract_audit.py",
                "postgres_is_product_truth",
                "hermes_is_lab_cache",
                "ready_for_strategy_matrix",
                "structure_ready_source_missing",
                "local_runtime_reference_profiles",
                "local_runtime_profile_count",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CORE_ROLE_AUDIT,
            [
                "global_commander_core_role_audit",
                "CORE_ROLE_BANDS",
                "structured_tags_first_then_oracle_text_diagnostic_fallback",
                "benchmark_regression_only_not_global_template",
                "battle_or_optimization_performed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS,
            [
                "global_commander_core_repair_hypothesis",
                "mutation_allowed",
                "needs_mana_base_profile_before_named_cards",
                "needs_commander_win_plan_source_lane",
                "review_only_requires_commander_color_identity_and_fit",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_MANA_BASE_PROFILE,
            [
                "global_commander_mana_base_profile",
                "mutation_allowed",
                "mana_profile_ready_for_named_land_candidate_pool",
                "blocked_missing_commander_color_identity",
                "direct_or_fetch_access_by_color",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL,
            [
                "global_commander_named_land_candidate_pool",
                "review_only_named_land_candidate",
                "color_identity_allowed",
                "commander_legality",
                "current_deck_names",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL,
            [
                "global_commander_land_cut_candidate_model",
                "review_only_land_add_cut_pair",
                "carries_missing_core_role",
                "printed_deck_construction_exception_requires_source_lane",
                "potential_topdeck_engine_anchor_requires_commander_source_lane",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_POLICY_BUILDER,
            [
                "global_commander_land_floor_policy_builder",
                "calibrate_land_floor_policy_before_candidate_copy",
                "LAND_POLICY_READY_STATUS",
                "land_floor_policy_ready_for_pair_preflight_no_deck_action",
                "run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane",
                "candidate_copy_allowed_now",
                "land_floor_policy_is_not_materialization_permission",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_POLICY_BUILDER_TEST,
            [
                "test_land_floor_policy_builds_preflight_queue_without_opening_copy",
                "test_non_land_role_axis_policy_blocks_land_floor_calibration",
                "test_missing_reviewable_cut_pool_blocks_candidate_copy_preflight",
                "Battlefield Forge",
                "Expensive Engine",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_SYNTHESIZER,
            [
                "global_commander_land_floor_package_synthesizer",
                "land_floor_package_synthesized_candidate_copy_ready",
                "materialize_land_floor_package_candidate_copy",
                "single swaps are blocked when the floor remains unrepaired",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_SYNTHESIZER_TEST,
            [
                "test_synthesizes_full_land_gap_package_and_allows_candidate_copy",
                "test_blocks_when_unique_pairs_do_not_cover_land_gap",
                "Fixing Land 1",
                "Cut Spell 1",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL,
            [
                "global_commander_nonland_core_candidate_model",
                "format_staples_expanded_role_pool",
                "review_only_nonland_add_cut_pair",
                "review_nonland_add_cut_pool_ready",
                "needs_commander_specific_source_lane",
                "kaalia_angel_demon_dragon_payoff_requires_source_lane",
                "commander_payoff_protection",
                "cross_lane_ramp_cut_requires_same_lane_source_or_gate",
                "cross_lane_ramp_protection",
                "DEFAULT_BATTLE_FEEDBACK_REPORT",
                "blocked_by_global_battle_feedback",
                "battle_feedback_pair_memory",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LEARNING_PRIORITY_AUDIT,
            [
                "global_commander_learning_priority_audit",
                "EXTERNAL_RESEARCH_SNAPSHOT",
                "land_add_cut_pool_ready_review_only",
                "nonland_add_cut_pool_ready_review_only",
                "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only",
                "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only",
                "global_commander_battle_feedback_model_20260705_current",
                "DEFAULT_SOURCE_EXHAUSTION_REPORT",
                "DEFAULT_ENGINE_AXIS_PIVOT_REPORT",
                "DEFAULT_ROLE_AXIS_EXHAUSTION_REPORT",
                "source_exhaustion_router_before_candidate_copy",
                "engine_axis_exhaustion_router_before_more_same_deck_engine_research",
                "role_axis_exhaustion_router_before_more_same_deck_axis_research",
                "engine_axis_exhausted_requires_global_learning_pivot",
                "role_axis_exhausted_requires_global_learning_pivot",
                "pivot_to_cross_commander_role_axis_learning_after_engine_axis_exhaustion",
                "pivot_to_cross_commander_role_axis_learning_after_{axis}_axis_exhaustion",
                "source_exhaustion_gate_counts",
                "engine_axis_pivot_gate_counts",
                "role_axis_exhaustion_gate_counts",
                "battle_feedback_model_before_requeue",
                "blocked_exact_add_cut_pair_count",
                "current_official_bracket_model_has_five_brackets_and_game_changers",
                "benchmark_regression_only_not_global_template",
                "battle_or_optimization_performed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CROSS_COMMANDER_ROLE_AXIS_LEARNING_PIVOT,
            [
                "global_commander_cross_commander_role_axis_learning_pivot",
                "source_cycle_decks_need_role_axis_policy_before_more_same_deck_source_expansion",
                "ENGINE_AXIS_EXHAUSTED_STATE",
                "ROLE_AXIS_EXHAUSTED_STATE",
                "cross_commander_role_axis_suppressed_engine_axis_exhausted",
                "axis_suppressed_by_role_axis_exhaustion",
                "cross_commander_role_axis_suppressed_{role}_axis_exhausted",
                "engine_axis_exhaustion_suppresses_engine_reentry_until_new_card_level_evidence",
                "role_axis_exhaustion_suppresses_same_axis_reentry_until_new_card_level_evidence",
                "deck_607_is_benchmark_evidence_only_not_action_source",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CROSS_COMMANDER_ROLE_AXIS_LEARNING_PIVOT_TEST,
            [
                "test_source_cycle_prioritizes_role_axis_without_deck_action",
                "test_engine_axis_exhaustion_suppresses_engine_reentry",
                "test_role_axis_exhaustion_suppresses_ramp_reentry",
                "source_expansion_cycle_requires_global_learning_pivot",
                "engine_axis_exhausted_requires_global_learning_pivot",
                "role_axis_exhausted_requires_global_learning_pivot",
                "Kaalia Variant",
                "benchmark_only_excluded_from_action_count",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ROLE_AXIS_POLICY_BUILDER,
            [
                "global_commander_role_axis_policy_builder",
                "role_axis_policy_blocks_same_deck_source_cycle",
                "role_axis_policy_holds_exhausted_engine_axis",
                "role_axis_policy_holds_exhausted_role_axis",
                "axis_suppressed_by_role_axis_exhaustion",
                "treat_engine_as_capacity_ceiling_not_missing_role",
                "hold_engine_axis_after_biotransference_protection_exhaustion",
                "hold_{role}_axis_after_current_cut_lane_exhaustion",
                "apply_{role}_axis_policy_before_more_same_deck_source_expansion",
                "engine_saturation_policy_must_be_applied_before_more_same_deck_source_expansion",
                "candidate_copy_allowed_now",
                "mutation_boundary",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ROLE_AXIS_POLICY_BUILDER_TEST,
            [
                "test_engine_cycle_blocks_same_deck_source_expansion",
                "test_engine_axis_exhaustion_holds_engine_and_routes_next_axis",
                "test_role_axis_exhaustion_holds_ramp_and_routes_next_axis",
                "apply_engine_axis_policy_to_nonland_cut_model_before_more_same_deck_source_expansion",
                "apply_ramp_axis_policy_before_more_same_deck_source_expansion",
                "treat_engine_as_capacity_ceiling_not_missing_role",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_AXIS_NONLAND_CUT_POLICY_MODEL,
            [
                "global_commander_engine_axis_nonland_cut_policy_model",
                "engine_axis_nonland_cut_policy_applied_review_only",
                "engine_axis_policy_review_cut_pressure_ready",
                "engine_axis_policy_blocks_cut_until_source_lane_review",
                "collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_AXIS_NONLAND_CUT_POLICY_MODEL_TEST,
            [
                "test_engine_policy_splits_ready_and_protected_cuts",
                "engine_only_excess_cut_pressure",
                "engine_overlap_excess_cut_pressure",
                "kaalia_attack_window_or_extra_combat",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_AXIS_NONLAND_CUT_POLICY_MODEL,
            [
                "global_commander_ramp_axis_nonland_cut_policy_model",
                "ramp_axis_nonland_cut_policy_applied_review_only",
                "ramp_axis_policy_review_cut_pressure_ready",
                "ramp_axis_policy_blocks_non_excess_overlap",
                "collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_AXIS_NONLAND_CUT_POLICY_MODEL_TEST,
            [
                "test_ramp_policy_splits_ready_and_protected_blocked_cuts",
                "ramp_only_excess_cut_pressure",
                "ramp_overlap_excess_cut_pressure",
                "kaalia_angel_demon_dragon_payoff",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_USAGE_SAME_LANE_PROOF_SCOUT,
            [
                "global_commander_ramp_cut_usage_same_lane_proof_scout",
                "ramp_cut_usage_same_lane_proof_blocks_candidate_copy",
                "ramp_cut_usage_observed_blocks_candidate_copy",
                "missing_current_scope_usage_trace_for_ramp_cuts",
                "no_explicit_same_lane_replacement_route_for_ramp_cut_pairs",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_USAGE_SAME_LANE_PROOF_SCOUT_TEST,
            [
                "test_usage_observed_and_no_same_lane_blocks_candidate_copy",
                "usage_observed_blocks_ramp_cuts:Arcane Signet",
                "missing_current_scope_usage_trace_for_ramp_cuts:Basalt Monolith",
                "no_explicit_same_lane_replacement_route_for_ramp_cut_pairs",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_FOLLOWUP_ROUTER,
            [
                "global_commander_ramp_cut_followup_router",
                "ramp_cut_followup_router_blocks_candidate_copy",
                "replacement_required_for_used_ramp_cuts",
                "structured_trace_review_required_for_ramp_cuts",
                "trace_required_for_ramp_cuts",
                "run_trace_plan_structured_review_and_replacement_search_before_candidate_copy",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_FOLLOWUP_ROUTER_TEST,
            [
                "test_routes_trace_structured_review_and_replacement_required_cuts",
                "trace_required_for_ramp_cuts:Basalt Monolith",
                "structured_trace_review_required_for_ramp_cuts:Grim Monolith",
                "replacement_required_for_used_ramp_cuts:Arcane Signet",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_TRACE_REPLACEMENT_GATE,
            [
                "global_commander_ramp_cut_trace_replacement_gate",
                "ramp_cut_trace_replacement_gate_needs_forced_access",
                "same_lane_ramp_candidate_needs_source_trace_review",
                "run_forced_access_trace_for_unexposed_ramp_cut",
                "candidate_copy_closed_after_ramp_trace_replacement_gate",
                "battle_replay_performed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_TRACE_REPLACEMENT_GATE_TEST,
            [
                "test_replacement_candidates_filter_color_and_current_deck",
                "Talisman of Conviction",
                "Smothering Tithe",
                "candidate_copy_closed_after_ramp_trace_replacement_gate",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_USAGE_SAME_LANE_PROOF_SCOUT,
            [
                "global_commander_engine_cut_usage_same_lane_proof_scout",
                "engine_cut_usage_same_lane_proof_blocks_candidate_copy",
                "engine_cut_usage_observed_blocks_candidate_copy",
                "missing_current_scope_usage_trace_for_engine_cuts",
                "no_explicit_same_lane_replacement_route_for_engine_cut_pairs",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_USAGE_SAME_LANE_PROOF_SCOUT_TEST,
            [
                "test_usage_observed_and_no_same_lane_blocks_candidate_copy",
                "usage_observed_blocks_engine_cuts:Biotransference",
                "missing_current_scope_usage_trace_for_engine_cuts:Archaeomancer's Map",
                "no_explicit_same_lane_replacement_route_for_engine_cut_pairs",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_FOLLOWUP_ROUTER,
            [
                "global_commander_engine_cut_followup_router",
                "engine_cut_followup_router_blocks_candidate_copy",
                "trace_required_for_engine_cuts",
                "replacement_required_for_used_engine_cuts",
                "run_trace_plan_and_replacement_search_before_candidate_copy",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_FOLLOWUP_ROUTER_TEST,
            [
                "test_routes_missing_trace_and_usage_blocked_cuts",
                "trace_required_for_engine_cuts:Archaeomancer's Map",
                "replacement_required_for_used_engine_cuts:Biotransference",
                "find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_GATE,
            [
                "global_commander_engine_cut_trace_replacement_gate",
                "engine_cut_trace_replacement_gate_needs_trace_review",
                "engine_cut_natural_trace_seen_without_usage_needs_manual_negative_review",
                "engine_replacement_candidates_found_needs_source_trace_review",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_GATE_TEST,
            [
                "test_replacement_candidates_filter_color_and_current_deck",
                "test_build_report_keeps_candidate_copy_closed",
                "candidate_copy_closed_after_trace_replacement_gate",
                "run_forced_access_trace_for_unexposed_engine_cut",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_REVIEWER,
            [
                "global_commander_engine_cut_trace_replacement_reviewer",
                "engine_cut_trace_replacement_review_blocks_candidate_copy",
                "trace_review_blocks_negative_clearance_equal_score_tutor_candidate",
                "no_exact_artifact_spell_engine_replacement_proof",
                "candidate_copy_allowed_now",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_REVIEWER_TEST,
            [
                "test_equal_score_tutor_candidate_blocks_negative_clearance",
                "test_exact_artifact_spell_engine_candidate_is_counted",
                "engine_cut_trace_replacement_review_blocks_candidate_copy",
                "no_exact_artifact_spell_engine_replacement_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_EXACT_REPLACEMENT_OR_NEW_CUT_FINDER,
            [
                "global_commander_engine_exact_replacement_or_new_cut_finder",
                "engine_exact_replacement_or_new_cut_not_found_locally",
                "no_local_exact_replacement_ready_for_source_trace",
                "no_new_unblocked_engine_cut_source",
                "expand_external_exact_artifact_engine_source_lanes_or_global_axis",
                "candidate_copy_allowed_now",
                "creature spells you control are artifacts",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_EXACT_REPLACEMENT_OR_NEW_CUT_FINDER_TEST,
            [
                "test_finds_only_legal_color_allowed_not_in_deck_exact_replacements",
                "test_report_keeps_candidate_copy_closed_and_surfaces_cut_blockers",
                "outside_commander_color_identity",
                "new_engine_cut_blocked_by_commander_plan_signal",
                "Not Artifact Conversion",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_SOURCE_EXPANDER,
            [
                "global_commander_external_exact_artifact_engine_source_expander",
                "external_exact_artifact_engine_source_lanes_expanded_no_deck_action",
                "review_external_exact_artifact_engine_candidates_locally_before_candidate_copy",
                "candidate_copy_allowed_now",
                "battle_gate_allowed_now",
                "promotion_allowed",
                "fetch_scryfall_cards",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_SOURCE_EXPANDER_TEST,
            [
                "test_external_candidates_filter_color_and_current_deck",
                "external_exact_engine_candidate_ready_for_local_review",
                "outside_commander_color_identity",
                "already_in_current_deck",
                "Conspiracy",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_CANDIDATE_REVIEWER,
            [
                "global_commander_external_exact_artifact_engine_candidate_reviewer",
                "external_exact_artifact_engine_candidate_review_blocks_candidate_copy",
                "external_exact_artifact_engine_candidate_review_ready_for_add_cut_model",
                "backfill_local_oracle_cache_for_external_exact_engine_seeds_before_add_cut_review",
                "model_external_exact_artifact_engine_add_cut_pairs_before_candidate_copy",
                "missing_local_oracle_cache",
                "candidate_copy_allowed_now",
                "battle_gate_allowed_now",
                "promotion_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_CANDIDATE_REVIEWER_TEST,
            [
                "test_review_requires_local_oracle_and_current_deck_absence",
                "local_external_exact_engine_candidate_ready_for_add_cut_review",
                "missing_local_oracle_cache",
                "already_in_current_deck",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ORACLE_BACKFILL,
            [
                "global_commander_external_exact_artifact_oracle_backfill",
                "external_exact_artifact_oracle_backfill_applied_review_rerun_required",
                "BACKFILL_SOURCE",
                "deck_rows_mutated",
                "candidate_copy_allowed_now",
                "battle_gate_allowed_now",
                "promotion_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ORACLE_BACKFILL_TEST,
            [
                "test_plan_and_apply_backfill_only_for_missing_reviewed_external_seed",
                "external_exact_artifact_oracle_backfill_plan_ready",
                "external_exact_artifact_oracle_backfill_applied_review_rerun_required",
                "Digsite Engineer",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_ADD_CUT_PAIR_MODEL,
            [
                "global_commander_external_exact_artifact_engine_add_cut_pair_model",
                "external_exact_artifact_engine_add_cut_pair_model_blocks_candidate_copy",
                "expand_exact_artifact_type_conversion_source_lane_or_keep_biotransference_protected",
                "artifact_type_conversion_engine",
                "candidate_copy_allowed_now",
                "battle_gate_allowed_now",
                "promotion_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_ADD_CUT_PAIR_MODEL_TEST,
            [
                "test_requires_type_conversion_signal_to_replace_biotransference",
                "add_cut_pair_blocked_by_same_lane_signal_gap",
                "add_cut_pair_ready_for_source_trace",
                "artifact_type_conversion_engine",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXACT_ARTIFACT_TYPE_CONVERSION_SOURCE_LANE_EXPANDER,
            [
                "global_commander_exact_artifact_type_conversion_source_lane_expander",
                "exact_artifact_type_conversion_source_lane_exhausted_keep_biotransference_protected",
                "fetch_scryfall_cards_allow_empty",
                "already_in_current_deck",
                "candidate_copy_allowed_now",
                "battle_gate_allowed_now",
                "promotion_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXACT_ARTIFACT_TYPE_CONVERSION_SOURCE_LANE_EXPANDER_TEST,
            [
                "test_type_conversion_lane_blocks_current_deck_and_surfaces_ready_outside_candidate",
                "exact_artifact_type_conversion_source_ready_for_add_cut_model",
                "already_in_current_deck",
                "Mardu Converter",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_BIOTRANSFERENCE_PROTECTION_PIVOT_ROUTER,
            [
                "global_commander_biotransference_protection_pivot_router",
                "biotransference_protected_engine_axis_exhausted_pivot_required",
                "return_to_global_role_axis_learning_priority_after_engine_axis_exhaustion",
                "biotransference_protected_no_outside_type_conversion_replacement",
                "non_biotransference_engine_cut_blocked_by_trace_review",
                "candidate_copy_allowed_now",
                "battle_gate_allowed_now",
                "promotion_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_BIOTRANSFERENCE_PROTECTION_PIVOT_ROUTER_TEST,
            [
                "test_protects_biotransference_and_pivots_when_no_engine_cut_is_viable",
                "biotransference_protected_engine_axis_exhausted_pivot_required",
                "trace_review_blocks_negative_clearance_equal_score_tutor_candidate",
                "viable_non_biotransference_engine_cut_count",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER,
            [
                "global_commander_candidate_copy_materializer",
                "candidate_materialized_structure_ready_next_gate_closed",
                "source_db_mutated",
                "source_unchanged",
                "validate_source_db_for_package",
                "global_commander_value_safe_stage_splitter",
                "load_stage_pairs",
                "global_commander_package_scope_reducer",
                "load_reduced_scope_pairs",
                "global_commander_land_floor_package_synthesizer",
                "load_land_floor_package_pairs",
                "model_pairs",
                "--stage",
                "stage add cards are already present",
                "source_matches_pair_report",
                "protected_blocked_cut_cards",
                "protected blocked cut cards are absent",
                "--allow-chained-source",
                "promotion_allowed",
                "allow_battle_gate_now",
                "allow_next_strategy_matrix",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_COPY_MATERIALIZER_TEST,
            [
                "test_blocks_chained_source_db_by_default",
                "test_blocks_source_missing_protected_cut_candidate",
                "test_materializes_value_safe_stage_pairs_only_in_candidate_copy",
                "test_materializes_reduced_scope_pairs_only_in_candidate_copy",
                "test_materializes_land_floor_package_pairs_only_in_candidate_copy",
                "source_matches_pair_report",
                "Protected Payoff",
                "Arena of Glory",
                "Ash Barrens",
                "Despark",
                "Smuggler's Share",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PACKAGE_SCOPE_REDUCER,
            [
                "global_commander_package_scope_reducer",
                "commander_package_scope_reduced_ready_for_candidate_copy",
                "commander_package_scope_reduction_blocks_candidate_copy",
                "reduced_scope_candidate_copy_allowed_now",
                "full_package_candidate_copy_allowed_now",
                "materialize_reduced_scope_candidate_copy",
                "backfill_value_safe_cuts_or_reduce_package_scope",
                "forced_usage_blocked_count",
                "synthesize_new_value_safe_cut_source_or_smaller_package_after_forced_access_block",
                "selection_policy",
                "no_value_safe_reduced_scope_pair_ready",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PACKAGE_SCOPE_REDUCER_TEST,
            [
                "test_reduces_scope_to_axis_closing_pair_when_cut_is_scarce",
                "test_blocks_when_no_value_safe_cut_exists",
                "test_post_forced_cut_block_routes_to_new_source_or_smaller_package",
                "Necromancy",
                "Cabal Ritual",
                "reduced_scope_dropped_adds:1",
                "forced_cut_access_blocks_unresolved_cut_reclassification:3",
                "no_value_safe_reduced_scope_pair_ready",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_STAGE_ONLY_CUT_EVIDENCE_PLAN,
            [
                "global_commander_stage_only_cut_evidence_plan",
                "stage_only_cut_evidence_plan_ready",
                "stage_only_cut_evidence_plan_blocks_no_stage_only_rows",
                "contextual_staple_same_lane_usage_review",
                "structural_staple_same_lane_or_equal_gate_proof",
                "global_battle_feedback_reopen_proof",
                "collect_stage_only_cut_evidence_before_value_safe_reclassification",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_STAGE_ONLY_CUT_EVIDENCE_PLAN_TEST,
            [
                "test_prioritizes_contextual_stage_review_before_structural_staples",
                "test_blocks_when_no_stage_only_rows_exist",
                "Professional Face-Breaker",
                "Dark Ritual",
                "Sunforger",
                "contextual_staple_same_lane_usage_review",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CONTEXTUAL_STAGE_CUT_EVIDENCE_COLLECTOR,
            [
                "global_commander_contextual_stage_cut_evidence_collector",
                "contextual_stage_cut_evidence_collected_no_value_safe_reclassification",
                "contextual_stage_cut_evidence_blocks_no_contextual_rows",
                "contextual_stage_cut_has_supporting_proof_needs_manual_value_safe_review",
                "contextual_staple_same_lane_usage_review",
                "usage_or_same_lane_or_replay_proof",
                "collect_usage_or_trace_evidence_for_contextual_stage_cuts",
                "value_safe_reclassification_allowed_now",
                "candidate_copy_allowed_now",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CONTEXTUAL_STAGE_CUT_EVIDENCE_COLLECTOR_TEST,
            [
                "test_collects_context_without_reclassifying_missing_usage_or_trace",
                "test_blocks_when_no_contextual_stage_rows_exist",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Ornithopter of Paradise",
                "usage_or_same_lane_or_replay_proof",
                "contextual_stage_cut_evidence_collected_no_value_safe_reclassification",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_SCOUT,
            [
                "global_commander_contextual_usage_trace_scout",
                "contextual_usage_trace_scout_no_current_trace_evidence",
                "contextual_usage_trace_scout_partial_current_trace_evidence",
                "contextual_usage_trace_scout_blocks_no_contextual_cards",
                "current_scope_usage_trace_candidate",
                "historical_or_cross_deck_trace_reference_not_proof",
                "planning_reference_not_usage_trace",
                "generate_or_import_current_scope_usage_trace_before_reclassification",
                "battle_run_performed",
                "value_safe_reclassification_allowed_now",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_SCOUT_TEST,
            [
                "test_counts_current_scope_usage_trace_without_opening_reclassification",
                "test_blocks_when_only_non_proof_references_exist",
                "Diabolic Intent",
                "Professional Face-Breaker",
                "Ornithopter of Paradise",
                "planning_reference_not_usage_trace",
                "historical_or_cross_deck_trace_reference_not_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_GENERATOR,
            [
                "global_commander_contextual_usage_trace_generator",
                "contextual_usage_trace_generated_all_current_usage_review_required",
                "contextual_usage_trace_generated_partial_current_usage_review_required",
                "row_belongs_to_target_player",
                "MANALOOM_KNOWLEDGE_DB",
                "MANALOOM_BATTLE_TARGET_DECK_ID",
                "battle_gate_performed",
                "value_safe_reclassification_allowed_now",
                "current_scope_usage_missing_for_cards",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_GENERATOR_TEST,
            [
                "test_generates_usage_trace_summary_without_opening_gates",
                "test_generated_replay_without_target_exposure_keeps_blocker",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Opponent",
                "contextual_usage_trace_generated_partial_current_usage_review_required",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_REVIEWER,
            [
                "global_commander_contextual_usage_trace_reviewer",
                "contextual_usage_trace_review_blocks_value_safe_reclassification",
                "usage_observed_blocks_value_safe_reclassification",
                "not_value_safe_from_current_trace",
                "same_lane_replacement_proof",
                "find_new_cut_source_lane_or_same_lane_replacement_proof_before_candidate_copy",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CONTEXTUAL_USAGE_TRACE_REVIEWER_TEST,
            [
                "test_usage_observed_blocks_value_safe_reclassification",
                "test_not_seen_requires_more_trace",
                "Diabolic Intent",
                "Ornithopter of Paradise",
                "contextual_usage_trace_review_blocks_value_safe_reclassification",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_REPLACEMENT_MODEL,
            [
                "global_commander_same_lane_replacement_model",
                "same_lane_replacement_model_routes_to_new_cut_source_lane",
                "same_lane_replacement_model_needs_proof_before_candidate_copy",
                "incidental_role_overlap_not_same_lane_proof",
                "collect_new_cut_source_lane_evidence_after_contextual_usage_block",
                "same_lane_replacement_proof_allowed_now",
                "value_safe_reclassification_allowed_now",
                "candidate_copy_allowed_now",
                "battle_gate_performed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_REPLACEMENT_MODEL_TEST,
            [
                "test_incidental_overlap_does_not_create_same_lane_proof",
                "test_explicit_same_lane_route_still_requires_proof_before_copy",
                "Bonehoard Dracosaur",
                "Professional Face-Breaker",
                "incidental_role_overlap_count",
                "same_lane_replacement_route_count",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_NEW_CUT_SOURCE_LANE_TRACE_COLLECTOR,
            [
                "global_commander_new_cut_source_lane_trace_collector",
                "new_cut_source_lane_trace_blocks_used_remaining_cuts",
                "remaining_cut_used_by_target_trace_blocks_value_safe",
                "remaining_cut_seen_without_usage_needs_negative_review",
                "remaining_cut_not_seen_needs_forced_access_or_more_trace",
                "force_access_or_expand_cut_source_lane_for_unresolved_remaining_cuts",
                "battle_replay_performed",
                "value_safe_reclassification_allowed_now",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_NEW_CUT_SOURCE_LANE_TRACE_COLLECTOR_TEST,
            [
                "test_target_usage_blocks_remaining_cut_and_ignores_opponent_event",
                "test_decision_only_trace_requires_negative_review",
                "Sunforger",
                "Dark Ritual",
                "Opponent",
                "remaining_cut_used_by_target_trace_blocks_value_safe",
            ],
        )
    )
    checks.append(
        check_contains(
            BATTLE_ANALYST,
            [
                "MANALOOM_FORCE_FOCUS_ACCESS_MODE",
                "MANALOOM_FOCUS_ACCESS_CARDS",
                "apply_forced_focus_access_to_opening_keep",
                "player_is_evaluation_target(player)",
                "forced_focus_access_applied",
                "emit_focus_card_access_snapshot",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_FORCE_FOCUS_ACCESS_SCOPE_TEST,
            [
                "test_forced_focus_access_applies_to_current_evaluation_target",
                "test_forced_focus_access_does_not_apply_to_non_target_player",
                "Kaalia of the Vast",
                "Dark Ritual",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_FORCED_CUT_ACCESS_TRACE_GENERATOR,
            [
                "global_commander_forced_cut_access_trace_generator",
                "forced_cut_access_trace_blocks_used_unresolved_cuts",
                "forced_access_usage_observed_blocks_value_safe",
                "MANALOOM_FORCE_FOCUS_ACCESS_MODE",
                "MANALOOM_FOCUS_ACCESS_CARDS",
                "expand_cut_source_lane_after_forced_access_blocks_current_unresolved_cuts",
                "forced_access_boundary",
                "target_boundary",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_FORCED_CUT_ACCESS_TRACE_GENERATOR_TEST,
            [
                "test_forced_access_usage_blocks_value_safe_reclassification",
                "test_forced_access_available_without_usage_needs_manual_review",
                "Dark Ritual",
                "Kaalia of the Vast",
                "forced_access_usage_observed_blocks_value_safe",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_POST_FORCED_RECOVERY_SYNTHESIZER,
            [
                "global_commander_post_forced_recovery_synthesizer",
                "post_forced_recovery_blocks_candidate_copy_needs_new_cut_source",
                "mine_new_value_safe_cut_source_before_package_resynthesis",
                "build_same_lane_or_equal_gate_proof_for_stage_only_cuts",
                "resynthesize_smaller_package_only_after_fresh_cut_proof",
                "no_value_safe_cut_source_after_forced_access",
                "candidate_copy_allowed_now",
                "battle_gate_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_POST_FORCED_RECOVERY_SYNTHESIZER_TEST,
            [
                "test_blocks_current_package_when_no_value_safe_cut_or_pair_exists",
                "test_routes_to_existing_reduced_scope_materializer_when_pair_is_ready",
                "post_forced_recovery_blocks_candidate_copy_needs_new_cut_source",
                "mine_new_value_safe_cut_source_before_package_resynthesis",
                "materialize_reduced_scope_candidate_copy",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_VALUE_SAFE_CUT_SOURCE_MINER,
            [
                "global_commander_value_safe_cut_source_miner",
                "value_safe_cut_source_hypotheses_ready_for_trace",
                "value_safe_cut_source_mining_blocks_package_resynthesis",
                "fresh_cut_source_hypothesis_needs_trace",
                "collect_usage_trace_for_new_cut_source_hypotheses",
                "value_safe_reclassification_allowed_now",
                "candidate_copy_allowed_now",
                "external-cut-policy-report",
                "external_policy_exclusions_consumed",
                "external_corpus_policy:",
                "protected_profile_role_",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_VALUE_SAFE_CUT_SOURCE_MINER_TEST,
            [
                "test_mines_fresh_nonprotected_hypothesis_for_trace",
                "test_blocks_when_only_protected_or_stage_only_sources_exist",
                "Off Profile Relic",
                "value_safe_cut_source_hypotheses_ready_for_trace",
                "collect_usage_trace_for_new_cut_source_hypotheses",
                "test_external_policy_exclusion_blocks_reusing_fresh_hypothesis",
                "external_corpus_policy:exclude_from_rerun_miner_until_new_internal_evidence",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PACKAGE_AXIS_BROADENING_PLAN,
            [
                "global_commander_package_axis_broadening_plan",
                "commander_package_axis_broadening_plan_ready_no_deck_action",
                "package_axis_broadening_not_ready_hypotheses_need_trace",
                "package_axis_mismatch_with_exhausted_cut_lanes",
                "resynthesize_package_with_same_lane_axis_requirements",
                "collect_external_nonpayoff_cut_lane_corpus",
                "incidental_payload_is_not_same_lane_cut_proof",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PACKAGE_AXIS_BROADENING_PLAN_TEST,
            [
                "test_mismatched_package_axis_routes_to_same_lane_resynthesis",
                "test_fresh_hypotheses_block_axis_broadening_until_trace",
                "test_same_lane_axis_still_requires_value_safe_cut_pair",
                "package_axis_mismatch_with_exhausted_cut_lanes",
                "resynthesize_package_with_same_lane_axis_requirements",
                "collect_external_nonpayoff_cut_lane_corpus",
                "same_lane_axis_still_needs_value_safe_cut_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_PACKAGE_RESYNTHESIZER,
            [
                "global_commander_same_lane_package_resynthesizer",
                "same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes",
                "same_lane_package_resynthesis_has_pair_candidates",
                "expand_same_lane_add_source_lanes_for_target_cut_roles",
                "hold_payoff_package_until_payoff_lane_has_own_cuts",
                "same_lane_add_source_lanes_missing_for_target_cut_roles",
                "payoff_axis_needs_own_value_safe_cut_or_same_lane_package_cut",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_PACKAGE_RESYNTHESIZER_TEST,
            [
                "test_payoff_only_package_blocks_candidate_copy_and_names_requirements",
                "test_existing_same_lane_axis_still_needs_value_safe_cut_proof",
                "test_ready_pair_count_only_opens_when_same_lane_axis_and_value_safe_cut_exist",
                "same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes",
                "mana_acceleration_replacement",
                "tutors_access_replacement",
                "same_lane_axes_still_need_value_safe_cut_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_ADD_SOURCE_LANE_EXPANDER,
            [
                "global_commander_same_lane_add_source_lane_expander",
                "same_lane_add_source_lanes_expanded_no_deck_action",
                "same_lane_add_source_lanes_need_external_research",
                "resynthesize_same_lane_package_from_source_lanes_before_cut_pairing",
                "external_same_lane_source_research_for_missing_axes",
                "review_only_same_lane_add_source_candidate",
                "land_candidate_requires_mana_base_lane_not_same_lane_nonland_replacement",
                "source_lanes_are_review_only_not_deck_actions",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_ADD_SOURCE_LANE_EXPANDER_TEST,
            [
                "test_expands_ready_source_lanes_for_all_required_axes",
                "test_missing_same_lane_axis_routes_to_external_research",
                "test_existing_and_color_incompatible_candidates_are_blocked",
                "same_lane_add_source_lanes_expanded_no_deck_action",
                "resynthesize_same_lane_package_from_source_lanes_before_cut_pairing",
                "missing_same_lane_add_source_axes:tutors_access_replacement",
                "not_commander_color_identity_compatible",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_PACKAGE_SOURCE_SYNTHESIZER,
            [
                "global_commander_same_lane_package_source_synthesizer",
                "same_lane_source_package_synthesized_no_cut_pairs",
                "same_lane_source_package_synthesis_blocks_on_missing_axes",
                "collect_value_safe_same_lane_cut_pairs_for_resynthesized_package",
                "review_only_same_lane_package_add",
                "selected_adds_are_unpaired",
                "value_safe_same_lane_cut_pairs_missing",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_PACKAGE_SOURCE_SYNTHESIZER_TEST,
            [
                "test_synthesizes_bounded_package_with_all_axes_covered",
                "test_missing_axis_blocks_source_package_synthesis",
                "test_package_size_limit_is_respected",
                "same_lane_source_package_synthesized_no_cut_pairs",
                "collect_value_safe_same_lane_cut_pairs_for_resynthesized_package",
                "external_same_lane_source_research_for_missing_axes",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_CUT_PAIR_COLLECTOR,
            [
                "global_commander_same_lane_cut_pair_collector",
                "same_lane_cut_pair_collection_blocks_candidate_copy",
                "same_lane_cut_pair_collection_partial_scope_reducer_required",
                "same_lane_cut_pairs_ready_for_scope_reducer",
                "collect_more_same_lane_cut_evidence_or_broaden_cut_source_lanes",
                "review_only_value_safe_same_lane_pair",
                "target_role_is_protected_profile_lane_requires_trace_or_equal_gate",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_CUT_PAIR_COLLECTOR_TEST,
            [
                "test_collects_exact_same_lane_pairs_without_opening_candidate_copy",
                "test_protected_haste_lane_stays_stage_only",
                "test_blocks_when_no_same_lane_cut_exists",
                "same_lane_cut_pairs_ready_for_scope_reducer",
                "same_lane_cut_pair_collection_blocks_candidate_copy",
                "target_role_is_protected_profile_lane_requires_trace_or_equal_gate",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_CUT_EVIDENCE_PLAN,
            [
                "global_commander_same_lane_cut_evidence_plan",
                "same_lane_cut_evidence_plan_ready_no_deck_action",
                "same_lane_cut_evidence_plan_ready_pairs_need_scope_reducer",
                "same_lane_cut_evidence_plan_blocks_no_stage_only_lane",
                "collect_trace_or_external_evidence_for_same_lane_stage_only_cuts",
                "protected_same_lane_usage_trace_or_equal_gate",
                "structural_staple_same_lane_or_equal_gate_proof",
                "prior_failed_gate_reopen_proof",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_CUT_EVIDENCE_PLAN_TEST,
            [
                "test_plans_evidence_for_stage_only_same_lane_cuts",
                "test_ready_pairs_route_to_scope_reducer",
                "test_no_stage_only_lane_routes_to_broader_research",
                "same_lane_cut_evidence_plan_ready_no_deck_action",
                "collect_trace_or_external_evidence_for_same_lane_stage_only_cuts",
                "structural_staple_same_lane_or_equal_gate_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_STAGE_CUT_TRACE_COLLECTOR,
            [
                "global_commander_same_lane_stage_cut_trace_collector",
                "same_lane_stage_cut_trace_collection_blocks_used_cuts",
                "same_lane_stage_cut_trace_collection_needs_negative_review",
                "same_lane_stage_cut_trace_collection_has_external_references_only",
                "same_lane_stage_cut_trace_collection_needs_trace_generation",
                "build_same_lane_replacement_or_find_new_cut_source_for_used_stage_cuts",
                "same_lane_stage_cut_usage_trace_blocks_value_safe",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_STAGE_CUT_TRACE_COLLECTOR_TEST,
            [
                "test_usage_trace_blocks_value_safe_reclassification",
                "test_external_reference_alone_needs_internal_trace",
                "test_missing_trace_and_external_routes_to_trace_generation",
                "same_lane_stage_cut_trace_collection_blocks_used_cuts",
                "same_lane_stage_cut_external_reference_needs_internal_trace",
                "generate_or_import_same_lane_stage_cut_usage_traces",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_USED_CUT_RECOVERY_ROUTER,
            [
                "global_commander_same_lane_used_cut_recovery_router",
                "same_lane_used_cut_recovery_routes_to_new_cut_source",
                "same_lane_used_cut_recovery_needs_replacement_proof",
                "same_lane_used_cut_recovery_blocks_no_used_cuts",
                "mine_or_research_new_same_lane_cut_source_before_candidate_copy",
                "used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_USED_CUT_RECOVERY_ROUTER_TEST,
            [
                "test_structural_used_cut_routes_to_new_cut_source",
                "test_used_cut_with_nonstructural_same_lane_route_needs_replacement_proof",
                "test_no_used_cuts_routes_to_other_stage_cut_review",
                "same_lane_used_cut_recovery_routes_to_new_cut_source",
                "same_lane_used_cut_recovery_needs_replacement_proof",
                "review_seen_or_external_stage_cuts_before_recovery",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_NEW_CUT_SOURCE_MINER,
            [
                "global_commander_same_lane_new_cut_source_miner",
                "same_lane_new_cut_source_hypotheses_ready_for_trace",
                "same_lane_new_cut_source_mining_exhausted_current_deck",
                "fresh_same_lane_cut_source_needs_trace",
                "blocked_recycled_cut_source",
                "broaden_same_lane_cut_research_or_package_axis_before_candidate_copy",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_NEW_CUT_SOURCE_MINER_TEST,
            [
                "test_fresh_same_lane_source_routes_to_trace_collection",
                "test_consumed_stage_cut_is_not_recycled_as_fresh",
                "test_payoff_overlap_is_blocked_and_routes_to_broaden_axis",
                "same_lane_new_cut_source_hypotheses_ready_for_trace",
                "same_lane_new_cut_source_mining_exhausted_current_deck",
                "broaden_same_lane_cut_research_or_package_axis_before_candidate_copy",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_CUT_AXIS_BROADENING_PLAN,
            [
                "global_commander_same_lane_cut_axis_broadening_plan",
                "same_lane_cut_axis_broadening_not_ready_fresh_sources_need_trace",
                "same_lane_cut_axis_broadening_plan_ready_no_deck_action",
                "collect_external_nonpayoff_same_lane_cut_corpus_for_exhausted_roles",
                "forbid_recycling_used_seen_stage_only_or_blocked_cuts",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SAME_LANE_CUT_AXIS_BROADENING_PLAN_TEST,
            [
                "test_fresh_sources_block_broadening_until_trace",
                "test_exhausted_roles_route_to_external_nonpayoff_corpus",
                "test_missing_role_source_routes_to_discovery_before_resynthesis",
                "same_lane_cut_axis_broadening_plan_ready_no_deck_action",
                "collect_external_nonpayoff_same_lane_cut_corpus_for_exhausted_roles",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_CORPUS_COLLECTOR,
            [
                "global_commander_external_nonpayoff_same_lane_cut_corpus_collector",
                "external_nonpayoff_same_lane_corpus_collected_no_cut_permission",
                "external_nonpayoff_same_lane_corpus_blocked_fresh_sources_need_trace",
                "map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery",
                "external_corpus_is_not_cut_permission",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_CORPUS_COLLECTOR_TEST,
            [
                "test_exhausted_roles_collect_corpus_without_cut_permission",
                "test_fresh_sources_block_external_corpus_until_trace",
                "test_role_without_scanned_sources_routes_to_source_discovery",
                "external_nonpayoff_same_lane_corpus_collected_no_cut_permission",
                "map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_POLICY_MAPPER,
            [
                "global_commander_external_nonpayoff_same_lane_cut_policy_mapper",
                "external_nonpayoff_same_lane_policy_ready_no_cut_permission",
                "external_nonpayoff_same_lane_policy_blocks_fresh_sources_need_trace",
                "discover_external_nonpayoff_same_lane_source_candidates_before_miner",
                "card_level_cut_permission_now",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_POLICY_MAPPER_TEST,
            [
                "test_exhausted_role_corpus_requires_source_discovery_before_miner",
                "test_fresh_sources_block_policy_until_trace",
                "external_nonpayoff_same_lane_policy_ready_no_cut_permission",
                "discover_external_nonpayoff_same_lane_source_candidates_before_miner",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_DISCOVERER,
            [
                "global_commander_external_nonpayoff_same_lane_source_candidate_discoverer",
                "external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission",
                "external_source_candidate_already_in_current_deck_needs_trace_policy",
                "external_source_candidate_ready_for_local_source_lane_review",
                "review_external_nonpayoff_same_lane_source_candidates_locally_before_miner",
                "card_level_cut_permission_now",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_DISCOVERER_TEST,
            [
                "test_discovers_named_candidates_without_cut_permission",
                "test_non_discovery_policy_roles_are_skipped",
                "external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission",
                "external_source_candidate_already_in_current_deck_needs_trace_policy",
                "external_source_candidate_ready_for_local_source_lane_review",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_REVIEWER,
            [
                "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer",
                "external_nonpayoff_same_lane_source_candidates_reviewed_miner_seed_ready_no_deck_action",
                "external_source_candidate_local_review_ready_for_miner_seed",
                "external_source_candidate_local_review_current_deck_trace_required",
                "rerun_same_lane_cut_source_miner_with_reviewed_external_nonpayoff_candidates",
                "miner_source_seed_allowed",
                "card_level_cut_permission_now",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_REVIEWER_TEST,
            [
                "test_reviews_local_source_candidates_without_deck_action",
                "test_role_mismatch_blocks_miner_seed",
                "external_nonpayoff_same_lane_source_candidates_reviewed_miner_seed_ready_no_deck_action",
                "external_source_candidate_local_review_blocks_role_mismatch",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER,
            [
                "global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner",
                "reviewed_external_seeded_cut_source_hypotheses_ready_for_trace",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "collect_trace_for_reviewed_external_seeded_cut_source_hypotheses",
                "reviewed_external_seed_missing_for_target_role",
                "fresh_seeded_same_lane_cut_source_count",
                "card_level_cut_permission_now",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_TEST,
            [
                "test_seeded_fresh_source_routes_to_trace",
                "test_recycled_source_stays_blocked_despite_seed",
                "test_unseeded_target_role_remains_blocked",
                "reviewed_external_seeded_cut_source_hypotheses_ready_for_trace",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_REVIEWED_EXTERNAL_SEEDED_CUT_TRACE_COLLECTOR,
            [
                "global_commander_reviewed_external_seeded_cut_trace_collector",
                "reviewed_external_seeded_cut_trace_needs_force_access",
                "reviewed_seeded_cut_hypothesis_used_by_target_trace_blocks_cut",
                "reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace",
                "force_access_or_expand_replay_window_for_seeded_hypotheses",
                "card_level_cut_permission_now",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_REVIEWED_EXTERNAL_SEEDED_CUT_TRACE_COLLECTOR_TEST,
            [
                "test_target_usage_blocks_seeded_hypothesis_cut",
                "test_seen_without_usage_requires_negative_review",
                "test_unseen_hypotheses_need_force_access",
                "reviewed_external_seeded_cut_trace_needs_force_access",
                "reviewed_external_seeded_cut_trace_blocks_used_hypotheses",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_REVIEWED_EXTERNAL_SEEDED_FORCE_ACCESS_TRACE_GENERATOR,
            [
                "global_commander_reviewed_external_seeded_force_access_trace_generator",
                "reviewed_external_seeded_forced_access_blocks_absent_hypotheses",
                "reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission",
                "rerun_seeded_cut_source_miner_against_current_evaluation_db",
                "run_forced_replay_seed",
                "focus_cards",
                "seeded_hypothesis_boundary",
                "card_level_cut_permission_now",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_REVIEWED_EXTERNAL_SEEDED_FORCE_ACCESS_TRACE_GENERATOR_TEST,
            [
                "test_forced_access_usage_blocks_seeded_hypothesis_cut",
                "test_forced_access_without_usage_still_does_not_open_cut_permission",
                "test_forced_access_not_found_routes_to_current_db_remine",
                "reviewed_external_seeded_forced_access_blocks_absent_hypotheses",
                "reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission",
                "rerun_seeded_cut_source_miner_against_current_evaluation_db",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER,
            [
                "global_commander_external_nonpayoff_seed_exhaustion_recovery_router",
                "external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review",
                "collect_current_deck_negative_review_for_external_nonpayoff_candidates",
                "current_deck_boundary",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_TEST,
            [
                "test_current_deck_candidate_routes_to_negative_review",
                "test_identity_gap_routes_to_identity_resolution_when_no_current_deck_candidate",
                "test_unseeded_role_routes_to_external_source_expansion",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR,
            [
                "global_commander_external_nonpayoff_current_deck_negative_review_collector",
                "external_current_deck_negative_review_blocks_used_candidates",
                "external_current_deck_candidate_used_by_target_blocks_negative_review",
                "negative_review_boundary",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR_TEST,
            [
                "test_usage_blocks_negative_review",
                "test_seen_without_usage_requires_manual_review",
                "test_unseen_candidates_need_force_access_or_broader_trace",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_MANUAL_NEGATIVE_TRACE_REVIEWER,
            [
                "global_commander_external_nonpayoff_manual_negative_trace_reviewer",
                "manual_negative_trace_review_blocks_static_silence_without_activation",
                "manual_negative_trace_review_blocks_land_lane_seen_without_usage",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_MANUAL_NEGATIVE_TRACE_REVIEWER_TEST,
            [
                "test_static_and_land_seen_without_usage_do_not_clear_negative_review",
                "Grand Abolisher",
                "Arena of Glory",
                "Silence",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_NEW_SOURCE_OR_REPLACEMENT_FINDER,
            [
                "global_commander_external_nonpayoff_new_source_or_replacement_finder",
                "new_external_source_candidates_ready_for_local_review",
                "current_deck_candidate_used_by_target_blocks_replacement_proof",
                "new_external_source_candidate_ready_for_local_miner_review",
                "route_land_candidate_to_mana_base_lane",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_NEW_SOURCE_OR_REPLACEMENT_FINDER_TEST,
            [
                "test_current_deck_usage_blocks_replacement_proof",
                "test_new_legal_outside_deck_candidate_is_ready_for_review",
                "test_land_candidate_routes_to_mana_base_lane",
                "Loran's Escape",
                "Hall of the Bandit Lord",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_NEW_SOURCE_CANDIDATE_REVIEWER,
            [
                "global_commander_external_nonpayoff_new_source_candidate_reviewer",
                "new_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "new_external_source_local_review_ready_for_seeded_miner",
                "new_external_source_local_review_blocks_current_deck",
                "package_access_limited_seed",
                "generic_tutor_seed_bracket_context_required",
                "mana_rock_seed_curve_pressure_review",
                "rerun_seeded_cut_source_miner_with_new_reviewed_external_nonpayoff_sources",
                "card_level_cut_permission_now",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_NEW_SOURCE_CANDIDATE_REVIEWER_TEST,
            [
                "test_ready_candidate_becomes_miner_seed_only",
                "test_current_deck_candidate_is_blocked_even_if_finder_ready",
                "test_equipment_tutor_seed_is_package_limited",
                "new_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "new_external_source_local_review_blocks_current_deck",
                "package_access_limited_seed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SOURCE_CANDIDATE_POOL_EXPANDER,
            [
                "global_commander_external_nonpayoff_source_candidate_pool_expander",
                "external_nonpayoff_source_candidate_pool_expanded_ready_for_local_review",
                "expanded_external_source_candidate_ready_for_local_review",
                "expanded_source_candidate_recycled_from_prior_seed_blocked",
                "expanded_source_candidate_already_in_current_deck_blocked",
                "expanded_source_candidate_blocks_commander_banned",
                "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
                "PREVIOUS_REPORT_RECYCLING_KEYS",
                "previous_report_count",
                "--previous-report",
                "wizards_commander_bans_2024_09_23",
                "candidate_copy_allowed_now",
                "card_level_cut_permission_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_SOURCE_CANDIDATE_POOL_EXPANDER_TEST,
            [
                "test_legal_outside_deck_candidate_is_ready_for_review",
                "test_previous_seed_is_blocked_as_recycled",
                "test_cumulative_previous_reports_block_old_expanded_candidates",
                "test_current_deck_and_banned_candidates_stay_blocked",
                "Boros Charm",
                "Swiftfoot Boots",
                "Mana Crypt",
                "expanded_source_candidate_blocks_commander_banned",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_LIVE_SOURCE_RESEARCH_EXPANDER,
            [
                "global_commander_external_nonpayoff_live_source_research_expander",
                "external_nonpayoff_live_source_research_expanded_ready_for_local_review",
                "LIVE_SOURCE_SNAPSHOTS",
                "LIVE_SOURCE_CANDIDATES",
                "Orim's Chant",
                "Unbreakable Formation",
                "Sword of the Animist",
                "Simian Spirit Guide",
                "Fable of the Mirror-Breaker",
                "candidate_copy_allowed_now",
                "card_level_cut_permission_now",
                "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_LIVE_SOURCE_RESEARCH_EXPANDER_TEST,
            [
                "test_live_candidates_are_review_seeds_only",
                "Orim's Chant",
                "Grand Abolisher",
                "Hall of the Bandit Lord",
                "expanded_source_candidate_already_in_current_deck_blocked",
                "expanded_source_candidate_land_lane_requires_mana_base_model",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_FOLLOWUP_LIVE_SOURCE_RESEARCH_EXPANDER,
            [
                "global_commander_external_nonpayoff_followup_live_source_research_expander",
                "manual_negative_trace_review_did_not_clear_current_deck_cuts",
                "cumulative_previous_candidates_remain_recycled_and_blocked",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_FOLLOWUP_LIVE_SOURCE_RESEARCH_EXPANDER_TEST,
            [
                "test_followup_blocks_recycled_and_emits_only_new_review_seeds",
                "Deflecting Swat",
                "Dolmen Gate",
                "Black Market Connections",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER,
            [
                "global_commander_external_nonpayoff_expanded_source_candidate_reviewer",
                "expanded_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "expanded_source_candidate_local_review_ready_for_seeded_miner",
                "expanded_source_candidate_local_review_blocks_current_deck",
                "expanded_source_candidate_local_review_blocks_commander_banned",
                "rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources",
                "fast_mana_seed_requires_bracket_and_game_changer_context",
                "high_power_tutor_seed_requires_bracket_and_game_changer_context",
                "candidate_copy_allowed_now",
                "card_level_cut_permission_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_TEST,
            [
                "test_ready_expanded_candidate_becomes_miner_seed_only",
                "test_current_deck_and_banned_candidates_are_blocked",
                "test_role_mismatch_blocks_ready_expander_row",
                "Boros Charm",
                "Mana Vault",
                "Mana Crypt",
                "expanded_source_candidate_local_review_blocks_commander_banned",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_FOLLOWUP_SOURCE_CANDIDATE_EXPANDER,
            [
                "global_commander_external_nonpayoff_followup_source_candidate_expander",
                "external_nonpayoff_followup_source_candidate_pool_expanded_ready_for_local_review",
                "cumulative_previous_candidate_name_count",
                "expanded_external_source_candidate_ready_for_local_review",
                "expanded_source_candidate_recycled_from_prior_seed_blocked",
                "all_prior_finder_reviewer_and_expander_candidates_are_recycled_and_blocked",
                "edhrec_kaalia_default_followup_2026_07_06",
                "wizards_current_banned_restricted_2026_06_29",
                "candidate_copy_allowed_now",
                "card_level_cut_permission_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_NONPAYOFF_FOLLOWUP_SOURCE_CANDIDATE_EXPANDER_TEST,
            [
                "test_new_candidate_is_ready_but_still_seed_only",
                "test_previous_report_candidate_is_recycled_and_blocked",
                "test_current_deck_candidate_stays_blocked",
                "test_land_ramp_artifact_can_seed_mana_research",
                "Blacksmith's Skill",
                "Diabolic Tutor",
                "Mana Vault",
                "Wayfarer's Bauble",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CUT_SOURCE_HYPOTHESIS_TRACE_COLLECTOR,
            [
                "global_commander_cut_source_hypothesis_trace_collector",
                "cut_source_hypothesis_trace_blocks_used_hypotheses",
                "hypothesis_used_by_target_trace_blocks_value_safe",
                "hypothesis_seen_without_usage_needs_negative_review",
                "hypothesis_not_seen_needs_more_trace_or_force_access",
                "mine_more_hypotheses_or_build_same_lane_proof",
                "value_safe_reclassification_allowed_now",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CUT_SOURCE_HYPOTHESIS_TRACE_COLLECTOR_TEST,
            [
                "test_target_usage_blocks_hypothesis_value_safe_reclassification",
                "test_unseen_hypotheses_require_more_trace",
                "Biotransference",
                "Maskwood Nexus",
                "cut_source_hypothesis_trace_blocks_used_hypotheses",
                "expand_replay_window_or_force_access_for_unseen_hypotheses",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CUT_HYPOTHESIS_SAME_LANE_PROOF,
            [
                "global_commander_cut_hypothesis_same_lane_proof",
                "cut_hypothesis_same_lane_proof_routes_to_more_mining",
                "cut_hypothesis_same_lane_proof_needs_explicit_evidence",
                "incidental_hypothesis_role_overlap_not_same_lane_proof",
                "Only package add covered_axes or selected_for_axis create an explicit same-lane route.",
                "mine_more_hypotheses_or_external_cut_source_research",
                "value_safe_reclassification_allowed_now",
                "candidate_copy_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CUT_HYPOTHESIS_SAME_LANE_PROOF_TEST,
            [
                "test_incidental_profile_overlap_does_not_create_same_lane_route",
                "test_explicit_same_lane_route_still_requires_proof_before_copy",
                "test_seen_without_usage_requires_negative_review_without_copy",
                "Dragon Mage",
                "Dedicated Draw Replacement",
                "cut_hypothesis_same_lane_proof_routes_to_more_mining",
                "manual_negative_review_or_force_access_for_seen_hypotheses",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_CUT_SOURCE_RESEARCH_PLAN,
            [
                "global_commander_external_cut_source_research_plan",
                "external_cut_source_research_plan_ready_no_deck_action",
                "collect_external_commander_reference_corpus_for_cut_candidates",
                "wizards_commander_brackets_2026_02_09",
                "edhrec_kaalia_current",
                "external_research_cannot_override_target_usage",
                "external_research_requires_negative_trace_review_first",
                "External usage and articles are evidence lanes, not final deck truth.",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_CUT_SOURCE_RESEARCH_PLAN_TEST,
            [
                "test_external_research_plan_keeps_deck_actions_closed",
                "external_cut_source_research_plan_ready_no_deck_action",
                "collect_external_commander_reference_corpus_for_cut_candidates",
                "external_research_cannot_override_target_usage",
                "external_research_requires_negative_trace_review_first",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_REFERENCE_CORPUS_COLLECTOR,
            [
                "global_commander_external_reference_corpus_collector",
                "external_reference_corpus_collected_no_cut_permission",
                "map_external_corpus_to_cut_policy_before_rerun_miner",
                "external_absence_cannot_override_target_usage",
                "external_corpus_supports_preserve_or_strict_same_lane_proof",
                "external_presence_requires_negative_trace_before_cut",
                "External corpus presence protects or routes review; absence is not proof",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_REFERENCE_CORPUS_COLLECTOR_TEST,
            [
                "test_external_corpus_keeps_cut_permissions_closed",
                "external_reference_corpus_collected_no_cut_permission",
                "map_external_corpus_to_cut_policy_before_rerun_miner",
                "external_corpus_supports_preserve_or_strict_same_lane_proof",
                "external_absence_cannot_override_target_usage",
                "external_absence_plus_seen_without_usage_requires_negative_review",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_CORPUS_CUT_POLICY_MAPPER,
            [
                "global_commander_external_corpus_cut_policy_mapper",
                "external_corpus_cut_policy_blocks_current_hypotheses",
                "rerun_value_safe_cut_source_miner_with_external_policy_exclusions",
                "exclude_from_rerun_miner_until_new_internal_evidence",
                "protect_from_rerun_miner_until_same_lane_or_equal_gate",
                "hold_for_negative_trace_review_before_rerun_miner",
                "miner_must_consume_policy_exclusions_before_reusing_current_hypotheses",
                "candidate_copy_allowed_now",
                "value_safe_reclassification_allowed_now",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_CORPUS_CUT_POLICY_MAPPER_TEST,
            [
                "test_policy_blocks_current_hypotheses_from_rerun_miner",
                "external_corpus_cut_policy_blocks_current_hypotheses",
                "rerun_value_safe_cut_source_miner_with_external_policy_exclusions",
                "protect_from_rerun_miner_until_same_lane_or_equal_gate",
                "exclude_from_rerun_miner_until_new_internal_evidence",
                "hold_for_negative_trace_review_before_rerun_miner",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_BATTLE_PROBE_AUDIT,
            [
                "global_commander_candidate_battle_probe_audit",
                "battle_probe_blocks_promotion",
                "candidate_underperformed_base_probe",
                "added_cards_not_exercised_in_replay_events",
                "stale_lorehold_mentions",
                "promotion_allowed",
                "larger_battle_gate_required",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_BATTLE_FEEDBACK_MODEL,
            [
                "global_commander_battle_feedback_model",
                "pair_blocked_by_failed_gate",
                "pair_needs_exposure_replay_before_gate",
                "failed_exercised_candidate_pair",
                "ready_for_larger_equal_gate",
                "block_pair_until_new_source_lane_or_cut",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_PACKAGE_CHAIN_AUDIT,
            [
                "global_commander_candidate_package_chain_audit",
                "materializer_steps",
                "materializer_pair_index",
                "model_pairs",
                "allow_chained_source",
                "source_reference_accepted",
                "materializer_chain_pass",
                "core_floor_repaired",
                "strategy_ready",
                "battle_gate_allowed_now",
                "promotion_allowed",
                "run_commander_specific_strategy_matrix_for_package_before_battle",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_PACKAGE_CHAIN_AUDIT_TEST,
            [
                "test_stage_materializer_expands_model_pairs_as_package_swaps",
                "test_explicit_chained_source_can_pass_when_source_is_unchanged",
                "stage_materializer_payload",
                "chained_materializer_payload",
                "Arena of Glory",
                "Smuggler's Share",
                "swap_count",
                "final_candidate_db",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_PACKAGE_STRATEGY_MATRIX,
            [
                "global_commander_candidate_package_strategy_matrix",
                "package_strategy_blocks_battle",
                "Commander-specific role targets",
                "battle_gate_allowed_now",
                "promotion_allowed",
                "repair_commander_profile_blockers_before_battle",
                "attack_window_cut_without_replacement",
                "LOREHOLD_PROFILE",
                "protected_profile_anchor_cut",
                "protected_anchor_boundary",
                "topdeck_miracle_setup",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PROFILE_BLOCKER_REPAIR_PLAN,
            [
                "global_commander_profile_blocker_repair_plan",
                "profile_blocker_repair_plan_ready",
                "profile_strategy_ready_no_repair_needed",
                "materialize_profile_repair_candidate_copy",
                "repair_or_restore_commander_attack_window_before_more_interaction",
                "repair_mana_base_to_commander_land_floor",
                "repair_commander_payoff_density_with_legal_source_lanes",
                "finish_spot_interaction_floor_with_same_lane_cut",
                "package_core_floor_repair_actions",
                "core_removal_floor",
                "repair_core_removal_floor_with_spot_interaction_source_lane",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PROFILE_REPAIR_CANDIDATE_MODEL,
            [
                "global_commander_profile_repair_candidate_model",
                "profile_repair_candidate_model_blocks_materialization",
                "profile_repair_candidate_model_ready_for_candidate_copy",
                "candidate_copy_allowed_now",
                "expand_commander_payoff_source_lane_before_candidate_copy",
                "needs_broader_commander_payoff_source_lane_before_materialization",
                "core_removal_floor",
                "reanimation_plan_b",
                "GLOBAL_FEEDBACK_STAGE_ONLY_CUTS",
                "STRUCTURAL_STAPLE_PROTECTED_CUTS",
                "global_battle_feedback_requires_new_same_lane_or_gate",
                "structural_foundation_staple_requires_same_lane_or_battle_proof",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PAYOFF_SOURCE_LANE_EXPANDER,
            [
                "global_commander_payoff_source_lane_expander",
                "commander_payoff_source_lane_expanded",
                "commander_payoff_source_lane_needs_external_or_oracle_backfill",
                "synthesize_commander_payoff_package_before_candidate_copy",
                "review_only_commander_payoff_source_candidate",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PAYOFF_PACKAGE_SYNTHESIZER,
            [
                "global_commander_payoff_package_synthesizer",
                "commander_payoff_package_synthesis_blocks_candidate_copy",
                "commander_payoff_package_synthesis_ready_for_candidate_copy",
                "review_only_synthesized_package_add",
                "review_only_synthesized_package_cut",
                "insufficient_reviewable_cuts_for_full_profile_package",
                "package_size_exceeds_materializer_review_limit",
                "materialize_synthesized_commander_package_chain_copy",
                "expand_commander_cut_source_lane_for_full_profile_package",
                "REANIMATION_AXIS",
                "reanimation_plan_b",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CUT_SOURCE_LANE_EXPANDER,
            [
                "global_commander_cut_source_lane_expander",
                "commander_cut_source_lane_expanded_stage_split_required",
                "commander_cut_source_lane_still_blocks_full_package",
                "commander_cut_source_lane_ready_for_candidate_copy",
                "review_only_expanded_cut_source_candidate",
                "stage_only_commander_cut_source_candidate",
                "blocked_commander_cut_source_candidate",
                "structural_foundation_staple_requires_same_lane_or_battle_proof",
                "commander_expected_package_anchor_requires_stage_proof",
                "global_battle_feedback_requires_new_same_lane_or_gate",
                "forced_cut_access_evidence",
                "forced_cut_access_blocks_unresolved_cut_reclassification",
                "--forced-cut-access-report",
                "backfill_value_safe_cuts_or_reduce_package_scope_after_forced_access_block",
                "forced_access_boundary",
                "split_synthesized_package_into_value_safe_stages",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CUT_SOURCE_LANE_EXPANDER_TEST,
            [
                "test_forced_access_usage_blocks_unresolved_cut_reclassification",
                "forced_cut_access_trace_blocks_used_unresolved_cuts",
                "forced_cut_access_blocks_unresolved_cut_reclassification:3",
                "backfill_value_safe_cuts_or_reduce_package_scope_after_forced_access_block",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_VALUE_SAFE_STAGE_SPLITTER,
            [
                "global_commander_value_safe_stage_splitter",
                "commander_value_safe_stage_split_ready_for_stage_candidate_copy",
                "commander_value_safe_stage_split_blocks_candidate_copy",
                "review_only_value_safe_stage_pair",
                "stage_ready_for_candidate_copy",
                "full_package_unpaired_adds",
                "materialize_value_safe_stage_1_candidate_copy",
                "battle_or_optimization_performed",
                "mutation_allowed",
            ],
        )
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_REPORT),
            "exists": GLOBAL_COMMANDER_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_REPORT.exists() else "fail",
            "missing": [] if GLOBAL_COMMANDER_REPORT.exists() else ["global_commander_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_MATRIX_REPORT),
            "exists": GLOBAL_COMMANDER_MATRIX_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_MATRIX_REPORT.exists() else "fail",
            "missing": [] if GLOBAL_COMMANDER_MATRIX_REPORT.exists() else ["global_commander_matrix_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_CORE_ROLE_REPORT),
            "exists": GLOBAL_COMMANDER_CORE_ROLE_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_CORE_ROLE_REPORT.exists() else "fail",
            "missing": [] if GLOBAL_COMMANDER_CORE_ROLE_REPORT.exists() else ["global_commander_core_role_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT),
            "exists": GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_CORE_REPAIR_HYPOTHESIS_REPORT.exists()
            else ["global_commander_core_repair_hypothesis_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT),
            "exists": GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_MANA_BASE_PROFILE_REPORT.exists()
            else ["global_commander_mana_base_profile_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT),
            "exists": GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_NAMED_LAND_CANDIDATE_POOL_REPORT.exists()
            else ["global_commander_named_land_candidate_pool_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT),
            "exists": GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_LAND_CUT_CANDIDATE_MODEL_REPORT.exists()
            else ["global_commander_land_cut_candidate_model_report"],
        }
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_POLICY_BUILDER_REPORT,
            [
                "Global Commander Land Floor Policy Builder",
                "land_floor_policy_ready_no_deck_action",
                "ready_pair_preflight_deck_count: `9`",
                "top_deck_id: `612`",
                "top_pair_add: `Ash Barrens`",
                "top_pair_cut: `Longshot, Rebel Bowman`",
                "candidate_copy_allowed_now: `false`",
                "run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane",
                "land_floor_policy_is_not_materialization_permission",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_SYNTHESIZER_REPORT,
            [
                "Global Commander Land Floor Package Synthesizer",
                "land_floor_package_synthesized_candidate_copy_ready",
                "land_gap: `7`",
                "selected_pair_count: `7`",
                "candidate_copy_allowed_now: `true`",
                "materialize_land_floor_package_candidate_copy",
                "Ash Barrens",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            ],
        )
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT),
            "exists": GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_NONLAND_CORE_CANDIDATE_MODEL_REPORT.exists()
            else ["global_commander_nonland_core_candidate_model_report"],
        }
    )
    checks.append(
        {
            "path": rel(GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT),
            "exists": GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT.exists(),
            "status": "pass" if GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT.exists() else "fail",
            "missing": []
            if GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT.exists()
            else ["global_commander_learning_priority_report"],
        }
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LEARNING_PRIORITY_REPORT,
            [
                "Global Commander Learning Priority Audit",
                "source_expansion_cycle_requires_global_learning_pivot",
                "engine_axis_exhausted_requires_global_learning_pivot",
                "pivot_to_cross_commander_role_axis_learning_after_engine_axis_exhaustion",
                "engine_axis_exhaustion_router_before_more_same_deck_engine_research",
                "Deck 607 is ranked only as a regression benchmark",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CROSS_COMMANDER_ROLE_AXIS_LEARNING_PIVOT_REPORT,
            [
                "Global Commander Cross-Commander Role Axis Learning Pivot",
                "cross_commander_role_axis_learning_pivot_ready_after_engine_axis_exhaustion_no_deck_action",
                "top_axis_role: `ramp`",
                "source_cycle_axis_count: `4`",
                "engine_axis_exhausted_axis_count: `1`",
                "engine_axis_suppressed_axis_count: `1`",
                "benchmark_only_excluded_from_action_count: `5`",
                "build_cross_commander_role_axis_policy_before_more_same_deck_source_expansion",
                "cross_commander_role_axis_suppressed_engine_axis_exhausted",
                "deck_607_is_benchmark_evidence_only_not_action_source",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ROLE_AXIS_POLICY_BUILDER_REPORT,
            [
                "Global Commander Role Axis Policy Builder",
                "role_axis_policy_ready_after_engine_axis_exhaustion_blocks_same_deck_source_cycle",
                "top_policy_role: `ramp`",
                "top_pressure_class: `ceiling_saturation_axis`",
                "source_cycle_deck_count: `1`",
                "engine_axis_exhausted_deck_count: `1`",
                "held_engine_axis_count: `1`",
                "candidate_copy_allowed_now: `false`",
                "apply_ramp_axis_policy_before_more_same_deck_source_expansion",
                "treat_ramp_above_range_as_cut_pressure_not_add_lane",
                "role_axis_policy_holds_exhausted_engine_axis",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LEARNING_PRIORITY_RAMP_AXIS_EXHAUSTION_REPORT,
            [
                "Global Commander Learning Priority Audit",
                "Role Axis Exhaustion Counts",
                "role_axis_exhausted_requires_global_learning_pivot",
                "pivot_to_cross_commander_role_axis_learning_after_ramp_axis_exhaustion",
                "role_axis_exhaustion_router_before_more_same_deck_axis_research",
                "Deck 607 is ranked only as a regression benchmark",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CROSS_COMMANDER_ROLE_AXIS_RAMP_EXHAUSTION_REPORT,
            [
                "Global Commander Cross-Commander Role Axis Learning Pivot",
                "cross_commander_role_axis_learning_pivot_ready_after_role_axis_exhaustion_no_deck_action",
                "top_axis_role: `land`",
                "role_axis_suppressed_axis_count: `1`",
                "cross_commander_role_axis_suppressed_ramp_axis_exhausted",
                "choose_next_non_exhausted_role_axis_after_ramp_axis_exhaustion",
                "role_axis_exhaustion_suppresses_same_axis_reentry_until_new_card_level_evidence",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ROLE_AXIS_POLICY_BUILDER_POST_RAMP_EXHAUSTION_REPORT,
            [
                "Global Commander Role Axis Policy Builder",
                "role_axis_policy_ready_after_role_axis_exhaustion_blocks_same_deck_source_cycle",
                "top_policy_role: `land`",
                "held_role_axis_count: `1`",
                "role_axis_policy_holds_exhausted_role_axis",
                "calibrate_land_floor_policy_before_candidate_copy",
                "exhausted_role_axis_cannot_reenter_without_new_card_level_evidence",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_AXIS_NONLAND_CUT_POLICY_MODEL_REPORT,
            [
                "Global Commander Engine Axis Nonland Cut Policy Model",
                "engine_axis_nonland_cut_policy_applied_review_only",
                "evaluated_cut_count: `12`",
                "engine_cut_pressure_ready_count: `2`",
                "protected_engine_cut_count: `6`",
                "candidate_copy_allowed_now: `false`",
                "collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure",
                "engine_axis_policy_blocks_cut_until_source_lane_review",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_AXIS_NONLAND_CUT_POLICY_MODEL_REPORT,
            [
                "Global Commander Ramp Axis Nonland Cut Policy Model",
                "ramp_axis_nonland_cut_policy_applied_review_only",
                "evaluated_cut_count: `24`",
                "ramp_cut_pressure_ready_count: `9`",
                "candidate_pair_count: `9`",
                "candidate_copy_allowed_now: `false`",
                "collect_card_level_usage_and_same_lane_proof_for_ramp_policy_cut_pressure",
                "ramp_axis_policy_blocks_non_excess_overlap",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_USAGE_SAME_LANE_PROOF_SCOUT_REPORT,
            [
                "Global Commander Ramp Cut Usage Same-Lane Proof Scout",
                "ramp_cut_usage_same_lane_proof_blocks_candidate_copy",
                "cut_card_count: `9`",
                "usage_blocked_cut_count: `3`",
                "missing_trace_cut_count: `5`",
                "explicit_same_lane_route_count: `0`",
                "pair_ready_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "usage_observed_blocks_ramp_cuts:Arcane Signet",
                "no_explicit_same_lane_replacement_route_for_ramp_cut_pairs",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_FOLLOWUP_ROUTER_REPORT,
            [
                "Global Commander Ramp Cut Follow-Up Router",
                "ramp_cut_followup_router_blocks_candidate_copy",
                "cut_count: `9`",
                "usage_blocked_cut_count: `3`",
                "missing_trace_cut_count: `5`",
                "structured_trace_review_required_count: `1`",
                "replacement_required_count: `3`",
                "trace_plan_count: `5`",
                "structured_review_count: `1`",
                "pair_ready_count: `0`",
                "no_explicit_same_lane_pair_count: `9`",
                "run_trace_plan_structured_review_and_replacement_search_before_candidate_copy",
                "replacement_required_for_used_ramp_cuts:Arcane Signet",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_TRACE_REPLACEMENT_GATE_REPORT,
            [
                "Global Commander Ramp Cut Trace Replacement Gate",
                "ramp_cut_trace_replacement_gate_needs_forced_access",
                "trace_card_count: `5`",
                "generated_replay_count: `3`",
                "trace_no_exposure_count: `2`",
                "trace_usage_observed_count: `3`",
                "structured_manual_review_count: `1`",
                "replacement_candidate_count: `12`",
                "strong_replacement_candidate_count: `2`",
                "candidate_copy_allowed_now: `false`",
                "battle_replay_performed: `true`",
                "run_forced_access_trace_for_unexposed_ramp_cut",
                "Fellwar Stone",
                "Commander's Sphere",
            ],
        )
    )
    checks.extend(
        [
            check_contains(
                GLOBAL_COMMANDER_RAMP_CUT_FORCED_ACCESS_TRACE_GENERATOR,
                [
                    "Generate forced-access traces for unexposed global Commander ramp cuts.",
                    "UNEXPOSED_RAMP_STATUS",
                    "ramp_cut_forced_access_usage_observed_blocks_cut",
                    "candidate_copy_allowed_now",
                ],
            ),
            check_contains(
                GLOBAL_COMMANDER_RAMP_CUT_FORCED_ACCESS_TRACE_GENERATOR_TEST,
                [
                    "Tests for ramp cut forced-access trace generation.",
                    "test_forced_access_usage_blocks_ramp_cut",
                    "test_forced_access_without_usage_needs_manual_review",
                ],
            ),
        ]
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_FORCED_ACCESS_TRACE_GENERATOR_REPORT,
            [
                "Global Commander Ramp Cut Forced Access Trace Generator",
                "ramp_cut_forced_access_trace_blocks_used_unexposed_cuts",
                "focus_card_count: `2`",
                "focus_cards: `Culling the Weak, Desperate Ritual`",
                "seed_count: `3`",
                "generated_replay_count: `3`",
                "forced_access_mode: `opening_hand`",
                "usage_blocked_count: `2`",
                "candidate_copy_allowed_now: `false`",
                "battle_replay_performed: `true`",
                "battle_gate_performed: `false`",
                "find_different_ramp_cut_or_exact_same_lane_replacement_after_forced_access",
                "forced_access_usage_observed_blocks_ramp_cut:Culling the Weak,Desperate Ritual",
                "candidate_copy_closed_after_ramp_forced_access_trace",
            ],
        )
    )
    checks.extend(
        [
            check_contains(
                GLOBAL_COMMANDER_RAMP_CUT_FORCED_RECOVERY_ROUTER,
                [
                    "Route ramp recovery after forced access blocks unexposed ramp cuts.",
                    "replacement_blocked_lower_staple_rank_than_used_cut",
                    "alternative_cut_needs_current_scope_trace",
                    "candidate_copy_allowed_now",
                ],
            ),
            check_contains(
                GLOBAL_COMMANDER_RAMP_CUT_FORCED_RECOVERY_ROUTER_TEST,
                [
                    "Tests for ramp cut forced recovery routing.",
                    "test_routes_to_alternative_trace_when_replacement_downgrades_used_staple",
                ],
            ),
        ]
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_CUT_FORCED_RECOVERY_ROUTER_REPORT,
            [
                "Global Commander Ramp Cut Forced Recovery Router",
                "ramp_cut_forced_recovery_routes_alternative_cut_trace",
                "blocked_ramp_cut_count: `9`",
                "replacement_candidate_count: `2`",
                "replacement_exact_ready_count: `0`",
                "replacement_blocked_count: `18`",
                "alternative_ramp_card_count: `24`",
                "alternative_trace_required_count: `2`",
                "alternative_manual_review_count: `2`",
                "candidate_copy_allowed_now: `false`",
                "trace_alternative_ramp_cut_candidates_before_candidate_copy",
                "replacement_blocked_lower_staple_rank_than_used_cut",
                "alternative_ramp_cut_requires_trace:Ornithopter of Paradise,Pyretic Ritual",
                "candidate_copy_closed_after_ramp_forced_recovery_router",
            ],
        )
    )
    checks.extend(
        [
            check_contains(
                GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_TRACE_GENERATOR,
                [
                    "Generate natural traces for alternative ramp cut targets.",
                    "alternative_ramp_cut_no_current_exposure_needs_force_access_or_more_trace",
                    "candidate_copy_allowed_now",
                ],
            ),
            check_contains(
                GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_TRACE_GENERATOR_TEST,
                [
                    "Tests for alternative ramp cut trace generation.",
                    "test_usage_blocks_alternative_cut",
                    "test_no_exposure_requires_more_trace",
                ],
            ),
        ]
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_TRACE_GENERATOR_REPORT,
            [
                "Global Commander Ramp Alternative Cut Trace Generator",
                "ramp_alternative_cut_trace_needs_force_access_or_more_trace",
                "focus_card_count: `2`",
                "focus_cards: `Ornithopter of Paradise, Pyretic Ritual`",
                "seed_count: `3`",
                "generated_replay_count: `3`",
                "usage_blocked_count: `0`",
                "manual_review_count: `0`",
                "no_exposure_count: `2`",
                "candidate_copy_allowed_now: `false`",
                "battle_replay_performed: `true`",
                "battle_gate_performed: `false`",
                "force_access_or_expand_trace_for_alternative_ramp_cut",
                "alternative_ramp_cut_no_exposure_requires_force_or_more_trace:Ornithopter of Paradise,Pyretic Ritual",
                "candidate_copy_closed_after_alternative_ramp_cut_trace",
            ],
        )
    )
    checks.extend(
        [
            check_contains(
                GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_FORCED_ACCESS_TRACE_GENERATOR,
                [
                    "Generate forced-access traces for unexposed alternative ramp cut targets.",
                    "alternative_ramp_cut_forced_access_usage_observed_blocks_cut",
                    "candidate_copy_allowed_now",
                ],
            ),
            check_contains(
                GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_FORCED_ACCESS_TRACE_GENERATOR_TEST,
                [
                    "Tests for alternative ramp cut forced-access traces.",
                    "test_forced_usage_blocks_alternative_cut",
                    "test_forced_available_without_usage_needs_manual_review",
                ],
            ),
        ]
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_ALTERNATIVE_CUT_FORCED_ACCESS_TRACE_GENERATOR_REPORT,
            [
                "Global Commander Ramp Alternative Cut Forced Access Trace Generator",
                "ramp_alternative_cut_forced_access_blocks_used_targets",
                "focus_card_count: `2`",
                "focus_cards: `Ornithopter of Paradise, Pyretic Ritual`",
                "seed_count: `3`",
                "generated_replay_count: `3`",
                "forced_access_mode: `opening_hand`",
                "usage_blocked_count: `2`",
                "manual_review_count: `0`",
                "force_failure_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "battle_replay_performed: `true`",
                "battle_gate_performed: `false`",
                "expand_ramp_cut_source_or_pivot_role_axis_after_alternative_forced_access",
                "alternative_ramp_cut_forced_usage_observed_blocks_cut:Ornithopter of Paradise,Pyretic Ritual",
                "candidate_copy_closed_after_alternative_ramp_cut_forced_access",
            ],
        )
    )
    checks.extend(
        [
            check_contains(
                GLOBAL_COMMANDER_RAMP_AXIS_EXHAUSTION_ROUTER,
                [
                    "Route global Commander learning after current ramp cut lanes exhaust.",
                    "ramp_axis_exhausted_requires_global_role_axis_pivot",
                    "candidate_copy_allowed_now",
                ],
            ),
            check_contains(
                GLOBAL_COMMANDER_RAMP_AXIS_EXHAUSTION_ROUTER_TEST,
                [
                    "Tests for ramp axis exhaustion routing.",
                    "test_routes_to_global_pivot_when_ramp_lane_is_exhausted",
                    "test_does_not_mark_exhausted_with_ready_replacement",
                ],
            ),
        ]
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_RAMP_AXIS_EXHAUSTION_ROUTER_REPORT,
            [
                "Global Commander Ramp Axis Exhaustion Router",
                "ramp_axis_exhausted_requires_global_role_axis_pivot",
                "exhausted_role_axis: `ramp`",
                "blocked_ramp_cut_count: `9`",
                "replacement_exact_ready_count: `0`",
                "alternative_focus_card_count: `2`",
                "alternative_forced_usage_blocked_count: `2`",
                "current_ramp_lane_exhausted: `true`",
                "candidate_copy_allowed_now: `false`",
                "return_to_global_role_axis_learning_priority_after_ramp_axis_exhaustion",
                "ramp_axis_current_cut_lane_exhausted",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_USAGE_SAME_LANE_PROOF_SCOUT_REPORT,
            [
                "Global Commander Engine Cut Usage Same-Lane Proof Scout",
                "engine_cut_usage_same_lane_proof_blocks_candidate_copy",
                "usage_blocked_cut_count: `1`",
                "missing_trace_cut_count: `1`",
                "explicit_same_lane_route_count: `0`",
                "pair_ready_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "usage_observed_blocks_engine_cuts:Biotransference",
                "missing_current_scope_usage_trace_for_engine_cuts:Archaeomancer's Map",
                "no_explicit_same_lane_replacement_route_for_engine_cut_pairs",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_FOLLOWUP_ROUTER_REPORT,
            [
                "Global Commander Engine Cut Follow-Up Router",
                "engine_cut_followup_router_blocks_candidate_copy",
                "usage_blocked_cut_count: `1`",
                "missing_trace_cut_count: `1`",
                "replacement_required_count: `1`",
                "trace_plan_count: `1`",
                "pair_ready_count: `0`",
                "no_explicit_same_lane_pair_count: `6`",
                "candidate_copy_allowed_now: `false`",
                "run_trace_plan_and_replacement_search_before_candidate_copy",
                "trace_required_for_engine_cuts:Archaeomancer's Map",
                "replacement_required_for_used_engine_cuts:Biotransference",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_GATE_REPORT,
            [
                "Global Commander Engine Cut Trace Replacement Gate",
                "engine_cut_trace_replacement_gate_needs_trace_review",
                "generated_replay_count: `3`",
                "trace_manual_review_count: `1`",
                "replacement_candidate_count: `12`",
                "strong_replacement_candidate_count: `2`",
                "candidate_copy_allowed_now: `false`",
                "battle_replay_performed: `true`",
                "review_engine_cut_trace_results_before_candidate_copy",
                "natural_trace_manual_negative_review_required:Archaeomancer's Map",
                "replacement_candidates_require_source_trace_review",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_CUT_TRACE_REPLACEMENT_REVIEWER_REPORT,
            [
                "Global Commander Engine Cut Trace Replacement Reviewer",
                "engine_cut_trace_replacement_review_blocks_candidate_copy",
                "trace_blocked_count: `1`",
                "explicit_same_lane_replacement_proof_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "battle_gate_allowed_now: `false`",
                "find_exact_artifact_spell_engine_replacement_or_new_engine_cut_before_candidate_copy",
                "no_exact_artifact_spell_engine_replacement_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_ENGINE_EXACT_REPLACEMENT_OR_NEW_CUT_FINDER_REPORT,
            [
                "Global Commander Engine Exact Replacement Or New Cut Finder",
                "engine_exact_replacement_found_needs_source_trace",
                "exact_replacement_ready_count: `5`",
                "new_unblocked_engine_cut_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "source_trace_exact_engine_replacement_before_candidate_copy",
                "Digsite Engineer",
                "Ravenous Robots",
                "no_new_unblocked_engine_cut_source",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_SOURCE_EXPANDER_REPORT,
            [
                "Global Commander External Exact Artifact Engine Source Expander",
                "external_exact_artifact_engine_source_lanes_expanded_no_deck_action",
                "ready_for_local_review_count: `5`",
                "candidate_copy_allowed_now: `false`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "review_external_exact_artifact_engine_candidates_locally_before_candidate_copy",
                "Digsite Engineer",
                "Golem Foundry",
                "Poetic Ingenuity",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_CANDIDATE_REVIEWER_REPORT,
            [
                "Global Commander External Exact Artifact Engine Candidate Reviewer",
                "external_exact_artifact_engine_candidate_review_ready_for_add_cut_model",
                "external_ready_input_count: `5`",
                "local_review_ready_count: `5`",
                "missing_local_oracle_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "model_external_exact_artifact_engine_add_cut_pairs_before_candidate_copy",
                "Digsite Engineer",
                "Ravenous Robots",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ORACLE_BACKFILL_REPORT,
            [
                "Global Commander External Exact Artifact Oracle Backfill",
                "external_exact_artifact_oracle_backfill_applied_review_rerun_required",
                "candidate_backfill_count: `5`",
                "backfill_applied_count: `5`",
                "source_db_mutated: `true`",
                "deck_rows_mutated: `false`",
                "rerun_external_exact_artifact_engine_candidate_reviewer_after_backfill",
                "Poetic Ingenuity",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXTERNAL_EXACT_ARTIFACT_ENGINE_ADD_CUT_PAIR_MODEL_REPORT,
            [
                "Global Commander External Exact Artifact Engine Add Cut Pair Model",
                "external_exact_artifact_engine_add_cut_pair_model_blocks_candidate_copy",
                "add_candidate_count: `5`",
                "replacement_required_cut_count: `1`",
                "ready_for_source_trace_pair_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "add_does_not_cover_cut_required_signals:artifact_type_conversion_engine",
                "expand_exact_artifact_type_conversion_source_lane_or_keep_biotransference_protected",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_EXACT_ARTIFACT_TYPE_CONVERSION_SOURCE_LANE_EXPANDER_REPORT,
            [
                "Global Commander Exact Artifact Type Conversion Source Lane Expander",
                "exact_artifact_type_conversion_source_lane_exhausted_keep_biotransference_protected",
                "fetched_query_count: `5`",
                "type_conversion_candidate_count: `1`",
                "ready_type_conversion_candidate_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "Biotransference",
                "protect_biotransference_and_pivot_to_non_biotransference_engine_cut_or_global_axis",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_BIOTRANSFERENCE_PROTECTION_PIVOT_ROUTER_REPORT,
            [
                "Global Commander Biotransference Protection Pivot Router",
                "biotransference_protected_engine_axis_exhausted_pivot_required",
                "type_conversion_lane_exhausted: `true`",
                "biotransference_protected: `true`",
                "viable_non_biotransference_engine_cut_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "Archaeomancer's Map",
                "return_to_global_role_axis_learning_priority_after_engine_axis_exhaustion",
            ],
        )
    )
    for path, spec in VOLATILE_HISTORICAL_REPORTS.items():
        volatile_historical_reports.append(check_volatile_historical_report(path, spec))
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_MATERIALIZER_REPORT,
            [
                "Global Commander Candidate Copy Materializer",
                "candidate_materialized_structure_ready_next_gate_closed",
                "source_artifact_type: `global_commander_land_floor_package_synthesizer`",
                "candidate: `7` swap(s)",
                "source_unchanged: `true`",
                "source_matches_pair_report: `true`",
                "allow_battle_gate_now: `false`",
                "allow_next_strategy_matrix: `true`",
                "Ash Barrens",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_CHAIN_REPORT,
            [
                "Global Commander Candidate Package Chain Audit",
                "status: `pass`",
                "swap_count: `7`",
                "materializer_chain_pass: `true`",
                "core_floor_repaired: `true`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "run_commander_specific_strategy_matrix_for_package_before_battle",
                "Ash Barrens",
                "Evolving Wilds",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_STRATEGY_REPORT,
            [
                "Global Commander Candidate Package Strategy Matrix",
                "package_strategy_blocks_battle",
                "commander: `Lorehold, the Historian`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "commander_profile_not_available",
                "repair_commander_profile_blockers_before_battle",
                "Ash Barrens",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_LAND_FLOOR_PACKAGE_STRATEGY_LOREHOLD_PROFILE_REPORT,
            [
                "Global Commander Candidate Package Strategy Matrix",
                "package_strategy_blocks_battle",
                "commander: `Lorehold, the Historian`",
                "profile_version: `lorehold_reference_profile_v1_2026-05-11`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "profile_lands_below_target",
                "protected_profile_anchor_cut:Pyromancer's Goggles",
                "protected_profile_anchor_cut:Call Forth the Tempest",
                "protected_profile_anchor_cut:Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "repair_commander_profile_blockers_before_battle",
                "protected_anchor_boundary",
                "Ash Barrens",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CANDIDATE_PACKAGE_STRATEGY_REPORT,
            [
                "Global Commander Candidate Package Strategy Matrix",
                "package_strategy_blocks_battle",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "profile_lands_below_target",
                "profile_angels_demons_dragons_payoffs_below_target",
                "profile_spot_interaction_below_target",
                "attack_window_cut_without_replacement",
                "repair_commander_profile_blockers_before_battle",
                "Path to Exile",
                "Rakdos Charm",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PROFILE_BLOCKER_REPAIR_REPORT,
            [
                "Global Commander Profile Blocker Repair Plan",
                "profile_blocker_repair_plan_ready",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "profile_lands_below_target",
                "profile_angels_demons_dragons_payoffs_below_target",
                "profile_spot_interaction_below_target",
                "attack_window_cut_without_replacement",
                "materialize_profile_repair_candidate_copy",
                "repair_or_restore_commander_attack_window_before_more_interaction",
                "repair_mana_base_to_commander_land_floor",
                "repair_commander_payoff_density_with_legal_source_lanes",
                "finish_spot_interaction_floor_with_same_lane_cut",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PROFILE_REPAIR_CANDIDATE_REPORT,
            [
                "Global Commander Profile Repair Candidate Model",
                "profile_repair_candidate_model_blocks_materialization",
                "candidate_copy_allowed_now: `false`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "expand_commander_payoff_source_lane_before_candidate_copy",
                "needs_broader_commander_payoff_source_lane_before_materialization",
                "Arena of Glory",
                "Hall of the Bandit Lord",
                "Despark",
                "Anguished Unmaking",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PAYOFF_SOURCE_LANE_REPORT,
            [
                "Global Commander Payoff Source Lane Expander",
                "commander_payoff_source_lane_expanded",
                "ready_candidates_cover_shortfall: `true`",
                "candidate_copy_allowed_now: `false`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "synthesize_commander_payoff_package_before_candidate_copy",
                "Balefire Dragon",
                "Ancient Copper Dragon",
                "Hellkite Charger",
                "Avacyn, Angel of Hope",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PAYOFF_PACKAGE_SYNTHESIS_REPORT,
            [
                "Global Commander Payoff Package Synthesizer",
                "commander_payoff_package_synthesis_blocks_candidate_copy",
                "selected_add_count: `21`",
                "selected_cut_count: `10`",
                "unpaired_add_count: `11`",
                "candidate_copy_allowed_now: `false`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "insufficient_reviewable_cuts_for_full_profile_package:required_21_ready_10",
                "package_size_exceeds_materializer_review_limit:required_21_limit_8",
                "expand_commander_cut_source_lane_for_full_profile_package",
                "Arena of Glory",
                "Despark",
                "Balefire Dragon",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_CUT_SOURCE_LANE_REPORT,
            [
                "Global Commander Cut Source Lane Expander",
                "commander_cut_source_lane_expanded_stage_split_required",
                "required_cut_count: `21`",
                "value_safe_cut_count: `18`",
                "stage_only_cut_count: `17`",
                "blocked_cut_count: `48`",
                "candidate_copy_allowed_now: `false`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "value_safe_cut_shortfall:required_21_ready_18",
                "full_package_size_exceeds_stage_limit:required_21_limit_8",
                "split_synthesized_package_into_value_safe_stages",
                "Archaeomancer's Map",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                "Necropotence",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_VALUE_SAFE_STAGE_SPLITTER_REPORT,
            [
                "Global Commander Value-Safe Stage Splitter",
                "commander_value_safe_stage_split_ready_for_stage_candidate_copy",
                "selected_add_count: `21`",
                "value_safe_cut_count: `18`",
                "paired_swap_count: `18`",
                "unpaired_add_count: `3`",
                "stage_count: `3`",
                "stage_candidate_copy_allowed_now: `true`",
                "full_package_candidate_copy_allowed_now: `false`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "full_package_unpaired_adds:required_21_paired_18",
                "materialize_value_safe_stage_1_candidate_copy",
                "Arena of Glory",
                "Archaeomancer's Map",
                "The Balrog of Moria",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_PACKAGE_SCOPE_REDUCER_REPORT,
            [
                "Global Commander Package Scope Reducer",
                "commander_package_scope_reduced_ready_for_candidate_copy",
                "reduced_scope_candidate_copy_allowed_now: `true`",
                "full_package_candidate_copy_allowed_now: `false`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "materialize_reduced_scope_candidate_copy",
                "reduced_scope_dropped_adds:6",
                "Necromancy",
                "Cabal Ritual",
                "reanimation_plan_b",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_REPAIR_SCOPE1_MATERIALIZER_REPORT,
            [
                "Global Commander Candidate Copy Materializer",
                "candidate_materialized_structure_ready_next_gate_closed",
                "candidate: `1` swap(s)",
                "source_artifact_type: `global_commander_package_scope_reducer`",
                "source_unchanged: `true`",
                "source_matches_pair_report: `true`",
                "promotion_allowed: `false`",
                "allow_battle_gate_now: `false`",
                "Necromancy",
                "Cabal Ritual",
                "reanimation_plan_b",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_REPAIR_SCOPE1_CHAIN_REPORT,
            [
                "Global Commander Candidate Package Chain Audit",
                "status: `pass`",
                "swap_count: `21`",
                "materializer_chain_pass: `true`",
                "core_floor_repaired: `true`",
                "strategy_ready: `true`",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "Necromancy",
                "Cabal Ritual",
                "run_commander_specific_strategy_matrix_for_package_before_battle",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_REPAIR_SCOPE1_STRATEGY_REPORT,
            [
                "Global Commander Candidate Package Strategy Matrix",
                "package_strategy_blocks_battle",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
                "blocker_count: `1`",
                "| `reanimation_plan_b` | 3 | 3 | 0 | `3-6` | `in_range` |",
                "| `angels_demons_dragons_payoffs` | 4 | 16 | 12 | `22-30` | `below_target` |",
                "profile_angels_demons_dragons_payoffs_below_target",
                "repair_commander_profile_blockers_before_battle",
                "Necromancy",
                "Cabal Ritual",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_PROFILE_BLOCKER_REPAIR_REPORT,
            [
                "Global Commander Profile Blocker Repair Plan",
                "profile_blocker_repair_plan_ready",
                "blocker_count: `1`",
                "repair_action_count: `1`",
                "profile_angels_demons_dragons_payoffs_below_target",
                "repair_commander_payoff_density_with_legal_source_lanes",
                "battle_gate_allowed_now: `false`",
                "promotion_allowed: `false`",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_PROFILE_REPAIR_CANDIDATE_REPORT,
            [
                "Global Commander Profile Repair Candidate Model",
                "profile_repair_candidate_model_blocks_materialization",
                "candidate_copy_allowed_now: `false`",
                "expand_commander_payoff_source_lane_before_candidate_copy",
                "needs_broader_commander_payoff_source_lane_before_materialization",
                "Diabolic Intent",
                "Dark Ritual",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_PAYOFF_SOURCE_LANE_REPORT,
            [
                "Global Commander Payoff Source Lane Expander",
                "commander_payoff_source_lane_expanded",
                "shortfall_to_min: `6`",
                "ready_candidate_count: `30`",
                "ready_candidates_cover_shortfall: `true`",
                "Dragon Mage",
                "Bonehoard Dracosaur",
                "Drakuseth, Maw of Flames",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_PAYOFF_PACKAGE_REPORT,
            [
                "Global Commander Payoff Package Synthesizer",
                "commander_payoff_package_synthesis_blocks_candidate_copy",
                "selected_add_count: `6`",
                "selected_cut_count: `5`",
                "unpaired_add_count: `1`",
                "insufficient_reviewable_cuts_for_full_profile_package:required_6_ready_5",
                "Akroma, Angel of Wrath",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_CUT_SOURCE_LANE_REPORT,
            [
                "Global Commander Cut Source Lane Expander",
                "commander_cut_source_lane_still_blocks_full_package",
                "required_cut_count: `6`",
                "value_safe_cut_count: `0`",
                "stage_only_cut_count: `15`",
                "value_safe_cut_shortfall:required_6_ready_0",
                "Professional Face-Breaker",
                "Diabolic Intent",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_PACKAGE_SCOPE_REDUCER_REPORT,
            [
                "Global Commander Package Scope Reducer",
                "commander_package_scope_reduction_blocks_candidate_copy",
                "value_safe_cut_count: `0`",
                "scoped_pair_count: `0`",
                "no_value_safe_reduced_scope_pair_ready",
                "Dragon Mage",
                "Akroma, Angel of Wrath",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_STAGE_ONLY_CUT_EVIDENCE_REPORT,
            [
                "Global Commander Stage-Only Cut Evidence Plan",
                "stage_only_cut_evidence_plan_ready",
                "required_cut_count: `6`",
                "value_safe_cut_count: `0`",
                "stage_only_cut_count: `15`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "collect_stage_only_cut_evidence_before_value_safe_reclassification",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Ornithopter of Paradise",
                "contextual_staple_same_lane_usage_review",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_CONTEXTUAL_STAGE_CUT_EVIDENCE_REPORT,
            [
                "Global Commander Contextual Stage Cut Evidence Collector",
                "contextual_stage_cut_evidence_collected_no_value_safe_reclassification",
                "contextual_row_count: `3`",
                "reclassification_ready_count: `0`",
                "missing_usage_or_trace_count: `3`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "collect_usage_or_trace_evidence_for_contextual_stage_cuts",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Ornithopter of Paradise",
                "usage_or_same_lane_or_replay_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_CONTEXTUAL_USAGE_TRACE_SCOUT_REPORT,
            [
                "Global Commander Contextual Usage Trace Scout",
                "contextual_usage_trace_scout_no_current_trace_evidence",
                "contextual_card_count: `3`",
                "current_usage_trace_evidence_count: `0`",
                "non_proof_reference_count: `163`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "battle_run_performed: `false`",
                "generate_or_import_current_scope_usage_trace_before_reclassification",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Ornithopter of Paradise",
                "no_current_scope_usage_trace_evidence_for_contextual_stage_cuts",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_CONTEXTUAL_USAGE_TRACE_GENERATOR_REPORT,
            [
                "Global Commander Contextual Usage Trace Generator",
                "contextual_usage_trace_generated_all_current_usage_review_required",
                "seed_count: `8`",
                "generated_replay_count: `8`",
                "usage_event_card_count: `3`",
                "battle_replay_performed: `true`",
                "battle_gate_performed: `false`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Ornithopter of Paradise",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_CONTEXTUAL_USAGE_TRACE_REVIEWER_REPORT,
            [
                "Global Commander Contextual Usage Trace Reviewer",
                "contextual_usage_trace_review_blocks_value_safe_reclassification",
                "usage_blocked_card_count: `3`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "find_new_cut_source_lane_or_same_lane_replacement_proof_before_candidate_copy",
                "usage_observed_blocks_value_safe_reclassification",
                "not_value_safe_from_current_trace",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Ornithopter of Paradise",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_REPLACEMENT_MODEL_REPORT,
            [
                "Global Commander Same-Lane Replacement Model",
                "same_lane_replacement_model_routes_to_new_cut_source_lane",
                "usage_blocked_cut_count: `3`",
                "same_lane_replacement_route_count: `0`",
                "incidental_role_overlap_count: `4`",
                "remaining_stage_only_cut_source_count: `12`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "collect_new_cut_source_lane_evidence_after_contextual_usage_block",
                "Professional Face-Breaker",
                "Diabolic Intent",
                "Ornithopter of Paradise",
                "Jeska's Will",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_NEW_CUT_SOURCE_LANE_TRACE_COLLECTOR_REPORT,
            [
                "Global Commander New Cut Source Lane Trace Collector",
                "new_cut_source_lane_trace_blocks_used_remaining_cuts",
                "remaining_cut_source_count: `12`",
                "usage_blocked_remaining_cut_count: `9`",
                "seen_without_usage_count: `2`",
                "not_seen_count: `1`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "force_access_or_expand_cut_source_lane_for_unresolved_remaining_cuts",
                "Sunforger",
                "Smothering Tithe",
                "Dark Ritual",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_FORCED_CUT_ACCESS_TRACE_GENERATOR_REPORT,
            [
                "Global Commander Forced Cut Access Trace Generator",
                "forced_cut_access_trace_blocks_used_unresolved_cuts",
                "focus_card_count: `3`",
                "usage_blocked_count: `3`",
                "manual_review_count: `0`",
                "force_failure_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "expand_cut_source_lane_after_forced_access_blocks_current_unresolved_cuts",
                "Alicia Masters, Skilled Sculptor",
                "Vampiric Tutor",
                "Dark Ritual",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_POST_FORCED_CUT_SOURCE_LANE_REPORT,
            [
                "Global Commander Cut Source Lane Expander",
                "commander_cut_source_lane_still_blocks_full_package",
                "value_safe_cut_count: `0`",
                "forced_cut_access_status: `forced_cut_access_trace_blocks_used_unresolved_cuts`",
                "forced_usage_blocked_count: `3`",
                "candidate_copy_allowed_now: `false`",
                "forced_cut_access_blocks_unresolved_cut_reclassification:3",
                "backfill_value_safe_cuts_or_reduce_package_scope_after_forced_access_block",
                "Dark Ritual",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_POST_FORCED_PACKAGE_SCOPE_REDUCER_REPORT,
            [
                "Global Commander Package Scope Reducer",
                "commander_package_scope_reduction_blocks_candidate_copy",
                "value_safe_cut_count: `0`",
                "scoped_pair_count: `0`",
                "dropped_add_count: `6`",
                "forced_usage_blocked_count: `3`",
                "reduced_scope_candidate_copy_allowed_now: `false`",
                "forced_cut_access_blocks_unresolved_cut_reclassification:3",
                "synthesize_new_value_safe_cut_source_or_smaller_package_after_forced_access_block",
                "Akroma, Angel of Wrath",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_POST_FORCED_RECOVERY_SYNTHESIZER_REPORT,
            [
                "Global Commander Post-Forced Recovery Synthesizer",
                "post_forced_recovery_blocks_candidate_copy_needs_new_cut_source",
                "selected_add_count: `6`",
                "required_cut_count: `6`",
                "value_safe_cut_count: `0`",
                "stage_only_cut_count: `15`",
                "forced_usage_blocked_count: `3`",
                "scoped_pair_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "mine_new_value_safe_cut_source_before_package_resynthesis",
                "no_value_safe_cut_source_after_forced_access",
                "Dragon Mage",
                "Akroma, Angel of Wrath",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_VALUE_SAFE_CUT_SOURCE_MINER_REPORT,
            [
                "Global Commander Value-Safe Cut Source Miner",
                "value_safe_cut_source_hypotheses_ready_for_trace",
                "hypothesis_count: `8`",
                "blocked_hypothesis_count: `80`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "collect_usage_trace_for_new_cut_source_hypotheses",
                "Biotransference",
                "Maskwood Nexus",
                "Sigarda's Aid",
                "Necromancy",
                "Sram, Senior Edificer",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_VALUE_SAFE_CUT_SOURCE_MINER_EXTERNAL_POLICY_REPORT,
            [
                "Global Commander Value-Safe Cut Source Miner",
                "value_safe_cut_source_mining_blocks_package_resynthesis",
                "hypothesis_count: `0`",
                "blocked_hypothesis_count: `88`",
                "external_policy_exclusion_count: `8`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "broaden_commander_package_axis_or_external_cut_research",
                "external_policy_exclusions_consumed:8",
                "external_policy_boundary",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_PACKAGE_AXIS_BROADENING_PLAN_REPORT,
            [
                "Global Commander Package Axis Broadening Plan",
                "commander_package_axis_broadening_plan_ready_no_deck_action",
                "selected_add_count: `6`",
                "selected_cut_count: `5`",
                "value_safe_cut_count: `0`",
                "fresh_hypothesis_count: `0`",
                "external_policy_exclusion_count: `8`",
                "lane_alignment_status: `package_axis_mismatch_with_exhausted_cut_lanes`",
                "package_axes: `angels_demons_dragons_payoffs`",
                "unmatched_cut_roles: `haste_protection_silence, mana_acceleration, tutors_access`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "resynthesize_package_with_same_lane_axis_requirements",
                "collect_external_nonpayoff_cut_lane_corpus",
                "incidental_payload_is_not_same_lane_cut_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_PACKAGE_RESYNTHESIZER_REPORT,
            [
                "Global Commander Same-Lane Package Resynthesizer",
                "same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes",
                "held_payoff_add_count: `6`",
                "same_lane_axis_requirement_count: `3`",
                "satisfied_same_lane_axis_count: `0`",
                "value_safe_cut_count: `0`",
                "ready_pair_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "expand_same_lane_add_source_lanes_for_target_cut_roles",
                "commander_attack_window",
                "mana_acceleration_replacement",
                "tutors_access_replacement",
                "hold_payoff_package_until_payoff_lane_has_own_cuts",
                "same_lane_add_source_lanes_missing_for_target_cut_roles",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_ADD_SOURCE_LANE_EXPANDER_REPORT,
            [
                "Global Commander Same-Lane Add Source Lane Expander",
                "same_lane_add_source_lanes_expanded_no_deck_action",
                "requirement_count: `3`",
                "ready_axis_count: `3`",
                "missing_axis_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "resynthesize_same_lane_package_from_source_lanes_before_cut_pairing",
                "commander_attack_window",
                "mana_acceleration_replacement",
                "tutors_access_replacement",
                "Boros Charm",
                "Fellwar Stone",
                "Gamble",
                "source_lanes_are_review_only_not_deck_actions",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_PACKAGE_SOURCE_SYNTHESIZER_REPORT,
            [
                "Global Commander Same-Lane Package Source Synthesizer",
                "same_lane_source_package_synthesized_no_cut_pairs",
                "package_size_limit: `8`",
                "selected_add_count: `8`",
                "axes_covered_count: `3`",
                "unpaired_add_count: `8`",
                "ready_pair_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "collect_value_safe_same_lane_cut_pairs_for_resynthesized_package",
                "Boros Charm",
                "Fellwar Stone",
                "Gamble",
                "Wishclaw Talisman",
                "selected_adds_are_unpaired",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_CUT_PAIR_COLLECTOR_REPORT,
            [
                "Global Commander Same-Lane Cut Pair Collector",
                "same_lane_cut_pair_collection_blocks_candidate_copy",
                "selected_add_count: `8`",
                "required_pair_count: `8`",
                "ready_pair_count: `0`",
                "unpaired_add_count: `8`",
                "stage_only_cut_candidate_count: `28`",
                "blocked_cut_candidate_count: `19`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "collect_more_same_lane_cut_evidence_or_broaden_cut_source_lanes",
                "Fellwar Stone",
                "Boros Charm",
                "Gamble",
                "Smothering Tithe",
                "structural_foundation_staple_requires_same_lane_or_battle_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_CUT_EVIDENCE_PLAN_REPORT,
            [
                "Global Commander Same-Lane Cut Evidence Plan",
                "same_lane_cut_evidence_plan_ready_no_deck_action",
                "selected_add_count: `8`",
                "ready_pair_count: `0`",
                "unpaired_add_count: `8`",
                "stage_only_cut_evidence_count: `28`",
                "hard_blocked_cut_count: `19`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "collect_trace_or_external_evidence_for_same_lane_stage_only_cuts",
                "protected_same_lane_usage_trace_or_equal_gate",
                "structural_staple_same_lane_or_equal_gate_proof",
                "prior_failed_gate_reopen_proof",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_STAGE_CUT_TRACE_COLLECTOR_REPORT,
            [
                "Global Commander Same-Lane Stage Cut Trace Collector",
                "same_lane_stage_cut_trace_collection_blocks_used_cuts",
                "stage_cut_count: `28`",
                "usage_blocked_count: `19`",
                "seen_without_usage_count: `4`",
                "external_reference_only_count: `1`",
                "needs_trace_or_external_research_count: `4`",
                "seed_report_count: `8`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "battle_replay_performed: `false`",
                "build_same_lane_replacement_or_find_new_cut_source_for_used_stage_cuts",
                "Smothering Tithe",
                "Diabolic Intent",
                "Mana Vault",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_USED_CUT_RECOVERY_ROUTER_REPORT,
            [
                "Global Commander Same-Lane Used Cut Recovery Router",
                "same_lane_used_cut_recovery_routes_to_new_cut_source",
                "used_cut_count: `19`",
                "strict_recovery_count: `10`",
                "same_lane_replacement_proof_count: `9`",
                "no_same_lane_route_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "mine_or_research_new_same_lane_cut_source_before_candidate_copy",
                "Smothering Tithe",
                "Demonic Tutor",
                "Mana Vault",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_NEW_CUT_SOURCE_MINER_REPORT,
            [
                "Global Commander Same-Lane New Cut Source Miner",
                "same_lane_new_cut_source_mining_exhausted_current_deck",
                "target_role_count: `3`",
                "exhausted_source_card_count: `42`",
                "scanned_same_lane_source_count: `47`",
                "fresh_same_lane_cut_source_count: `0`",
                "blocked_recycled_cut_source_count: `47`",
                "blocked_new_cut_source_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "broaden_same_lane_cut_research_or_package_axis_before_candidate_copy",
                "Smothering Tithe",
                "Mana Vault",
                "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_SAME_LANE_CUT_AXIS_BROADENING_PLAN_REPORT,
            [
                "Global Commander Same-Lane Cut Axis Broadening Plan",
                "same_lane_cut_axis_broadening_plan_ready_no_deck_action",
                "target_role_count: `3`",
                "scanned_same_lane_source_count: `47`",
                "fresh_same_lane_cut_source_count: `0`",
                "blocked_recycled_cut_source_count: `47`",
                "ready_pair_count: `0`",
                "unpaired_add_count: `8`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "collect_external_nonpayoff_same_lane_cut_corpus_for_exhausted_roles",
                "haste_protection_silence",
                "mana_acceleration",
                "tutors_access",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_CORPUS_COLLECTOR_REPORT,
            [
                "Global Commander External Nonpayoff Same-Lane Cut Corpus Collector",
                "external_nonpayoff_same_lane_corpus_collected_no_cut_permission",
                "target_role_count: `3`",
                "external_source_count: `6`",
                "role_corpus_count: `3`",
                "exhausted_role_count: `3`",
                "fresh_same_lane_cut_source_count: `0`",
                "blocked_recycled_cut_source_count: `47`",
                "ready_pair_count: `0`",
                "unpaired_add_count: `8`",
                "external_cut_permission_now: `false`",
                "candidate_copy_allowed_now: `false`",
                "map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery",
                "edhrec_kaalia_current_2026_07_05",
                "haste_protection_silence",
                "mana_acceleration",
                "tutors_access",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SAME_LANE_CUT_POLICY_MAPPER_REPORT,
            [
                "Global Commander External Nonpayoff Same-Lane Cut Policy Mapper",
                "external_nonpayoff_same_lane_policy_ready_no_cut_permission",
                "role_policy_count: `3`",
                "source_discovery_required_role_count: `3`",
                "rerun_miner_allowed_role_count: `0`",
                "card_level_cut_permission_count: `0`",
                "card_level_cut_permission_now: `false`",
                "candidate_copy_allowed_now: `false`",
                "discover_external_nonpayoff_same_lane_source_candidates_before_miner",
                "haste_protection_silence",
                "mana_acceleration",
                "tutors_access",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_DISCOVERER_REPORT,
            [
                "Global Commander External Nonpayoff Same-Lane Source Candidate Discoverer",
                "external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission",
                "source_candidate_count: `16`",
                "role_count: `3`",
                "current_deck_present_count: `6`",
                "outside_current_deck_count: `10`",
                "local_identity_found_count: `15`",
                "selected_as_package_add_count: `4`",
                "card_level_cut_permission_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "review_external_nonpayoff_same_lane_source_candidates_locally_before_miner",
                "Lightning Greaves",
                "Swiftfoot Boots",
                "Gamble",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SAME_LANE_SOURCE_CANDIDATE_REVIEWER_REPORT,
            [
                "Global Commander External Nonpayoff Same-Lane Source Candidate Reviewer",
                "external_nonpayoff_same_lane_source_candidates_reviewed_miner_seed_ready_no_deck_action",
                "reviewed_candidate_count: `16`",
                "miner_source_seed_allowed_count: `5`",
                "current_deck_trace_required_count: `6`",
                "held_package_pair_required_count: `4`",
                "identity_resolution_required_count: `1`",
                "role_mismatch_blocked_count: `0`",
                "card_level_cut_permission_count: `0`",
                "candidate_copy_allowed_count: `0`",
                "rerun_same_lane_cut_source_miner_with_reviewed_external_nonpayoff_candidates",
                "Dragon Tempest",
                "Dihada, Binder of Wills",
                "Simian Spirit Guide",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_REPORT,
            [
                "Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner",
                "reviewed_external_seeded_cut_source_hypotheses_ready_for_trace",
                "reviewed_seed_count: `5`",
                "seeded_role_count: `2`",
                "target_role_count: `3`",
                "unseeded_target_role_count: `1`",
                "scanned_seeded_same_lane_source_count: `34`",
                "fresh_seeded_same_lane_cut_source_count: `10`",
                "blocked_recycled_seeded_cut_source_count: `21`",
                "blocked_new_seeded_cut_source_count: `3`",
                "card_level_cut_permission_count: `0`",
                "candidate_copy_allowed_count: `0`",
                "collect_trace_for_reviewed_external_seeded_cut_source_hypotheses",
                "Basalt Monolith",
                "Monologue Tax",
                "Simian Spirit Guide",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_SEEDED_CUT_TRACE_COLLECTOR_REPORT,
            [
                "Global Commander Reviewed External Seeded Cut Trace Collector",
                "reviewed_external_seeded_cut_trace_needs_force_access",
                "hypothesis_count: `10`",
                "usage_blocked_hypothesis_count: `0`",
                "seen_without_usage_count: `0`",
                "not_seen_count: `10`",
                "seed_report_count: `8`",
                "card_level_cut_permission_count: `0`",
                "candidate_copy_allowed_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "force_access_or_expand_replay_window_for_seeded_hypotheses",
                "Basalt Monolith",
                "Monologue Tax",
                "Strike It Rich",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_SEEDED_FORCE_ACCESS_TRACE_GENERATOR_REPORT,
            [
                "Global Commander Reviewed External Seeded Force Access Trace Generator",
                "reviewed_external_seeded_forced_access_blocks_absent_hypotheses",
                "source_hypothesis_count: `10`",
                "focus_hypothesis_count: `10`",
                "seed_count: `3`",
                "usage_blocked_count: `0`",
                "selected_db_absent_count: `10`",
                "card_level_cut_permission_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "rerun_seeded_cut_source_miner_against_current_evaluation_db",
                "Basalt Monolith",
                "Cabal Ritual",
                "Strike It Rich",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_CURRENT_DB_REPORT,
            [
                "Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "reviewed_seed_count: `5`",
                "seeded_role_count: `2`",
                "target_role_count: `3`",
                "unseeded_target_role_count: `1`",
                "scanned_seeded_same_lane_source_count: `31`",
                "fresh_seeded_same_lane_cut_source_count: `0`",
                "blocked_recycled_seeded_cut_source_count: `31`",
                "blocked_new_seeded_cut_source_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy",
                "Dragon Tempest",
                "Simian Spirit Guide",
                "none",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_REPORT,
            [
                "Global Commander External Nonpayoff Seed Exhaustion Recovery Router",
                "external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review",
                "target_role_count: `3`",
                "seeded_exhausted_role_count: `2`",
                "unseeded_role_count: `1`",
                "current_deck_negative_review_candidate_count: `6`",
                "held_package_pair_required_count: `4`",
                "identity_resolution_required_count: `1`",
                "force_access_selected_db_absent_count: `10`",
                "candidate_copy_allowed_now: `false`",
                "Lightning Greaves",
                "Diabolic Intent",
                "collect_current_deck_negative_review_for_external_nonpayoff_candidates",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR_REPORT,
            [
                "Global Commander External Nonpayoff Current Deck Negative Review Collector",
                "external_current_deck_negative_review_blocks_used_candidates",
                "current_deck_candidate_count: `6`",
                "usage_blocked_candidate_count: `5`",
                "seen_without_usage_count: `1`",
                "not_seen_count: `0`",
                "negative_review_cleared_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "Lightning Greaves",
                "Vampiric Tutor",
                "find_new_external_source_or_explicit_same_lane_replacement_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_NEW_SOURCE_OR_REPLACEMENT_FINDER_REPORT,
            [
                "Global Commander External Nonpayoff New Source Or Replacement Finder",
                "new_external_source_candidates_ready_for_local_review",
                "current_deck_negative_review_candidate_count: `6`",
                "current_deck_usage_blocked_count: `5`",
                "manual_negative_review_required_count: `1`",
                "explicit_same_lane_replacement_proof_count: `0`",
                "new_external_candidate_count: `22`",
                "new_external_ready_for_review_count: `19`",
                "candidate_copy_allowed_now: `false`",
                "Lavaspur Boots",
                "Grim Tutor",
                "Stoneforge Mystic",
                "review_new_external_nonpayoff_source_candidates_locally_before_seeded_miner",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_NEW_SOURCE_CANDIDATE_REVIEWER_REPORT,
            [
                "Global Commander External Nonpayoff New Source Candidate Reviewer",
                "new_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "finder_ready_candidate_count: `19`",
                "reviewed_candidate_count: `19`",
                "miner_source_seed_allowed_count: `19`",
                "card_level_cut_permission_count: `0`",
                "candidate_copy_allowed_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "Lavaspur Boots",
                "Open the Armory",
                "Grim Tutor",
                "package_access_limited_seed",
                "generic_tutor_seed_bracket_context_required",
                "mana_rock_seed_curve_pressure_review",
                "rerun_seeded_cut_source_miner_with_new_reviewed_external_nonpayoff_sources",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_NEW_SOURCES_REPORT,
            [
                "Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "reviewed_seed_count: `19`",
                "seeded_role_count: `3`",
                "unseeded_target_role_count: `0`",
                "scanned_seeded_same_lane_source_count: `47`",
                "fresh_seeded_same_lane_cut_source_count: `0`",
                "blocked_recycled_seeded_cut_source_count: `47`",
                "blocked_new_seeded_cut_source_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "reviewed_external_seeds_found_no_fresh_current_deck_cut_source",
                "expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_NEW_SOURCES_REPORT,
            [
                "Global Commander External Nonpayoff Seed Exhaustion Recovery Router",
                "external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion",
                "target_role_count: `3`",
                "seeded_exhausted_role_count: `3`",
                "unseeded_role_count: `0`",
                "current_deck_negative_review_candidate_count: `0`",
                "prior_fresh_seeded_same_lane_cut_source_count: `0`",
                "prior_blocked_recycled_seeded_cut_source_count: `47`",
                "candidate_copy_allowed_now: `false`",
                "expand_external_nonpayoff_source_candidate_pool",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SOURCE_CANDIDATE_POOL_EXPANDER_REPORT,
            [
                "Global Commander External Nonpayoff Source Candidate Pool Expander",
                "external_nonpayoff_source_candidate_pool_expanded_ready_for_local_review",
                "expanded_candidate_count: `26`",
                "expanded_ready_for_review_count: `22`",
                "candidate_copy_allowed_count: `0`",
                "card_level_cut_permission_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "Swiftfoot Boots",
                "Boros Charm",
                "Fellwar Stone",
                "Wishclaw Talisman",
                "Mana Vault",
                "Mana Crypt",
                "Jeweled Lotus",
                "Dockside Extortionist",
                "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SOURCE_CANDIDATE_POOL_EXPANDER_FOLLOWUP_CUMULATIVE_REPORT,
            [
                "Global Commander External Nonpayoff Source Candidate Pool Expander",
                "external_nonpayoff_source_candidate_pool_expansion_found_no_ready_candidates",
                "expanded_candidate_count: `26`",
                "expanded_ready_for_review_count: `0`",
                "candidate_copy_allowed_count: `0`",
                "card_level_cut_permission_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "broaden_external_nonpayoff_source_research_live",
                "Swiftfoot Boots",
                "Boros Charm",
                "expanded_source_candidate_recycled_from_prior_seed_blocked",
                "Mana Vault",
                "Mana Crypt",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_LIVE_SOURCE_RESEARCH_EXPANDER_REPORT,
            [
                "Global Commander External Nonpayoff Live Source Research Expander",
                "external_nonpayoff_live_source_research_expanded_ready_for_local_review",
                "live_candidate_count: `24`",
                "live_ready_for_review_count: `7`",
                "candidate_copy_allowed_count: `0`",
                "card_level_cut_permission_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "Unbreakable Formation",
                "Orim's Chant",
                "Sword of the Animist",
                "Simian Spirit Guide",
                "Dihada, Binder of Wills",
                "Collector's Vault",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_REPORT,
            [
                "Global Commander External Nonpayoff Expanded Source Candidate Reviewer",
                "expanded_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "expander_ready_candidate_count: `22`",
                "reviewed_candidate_count: `26`",
                "miner_source_seed_allowed_count: `22`",
                "blocked_current_deck_count: `1`",
                "blocked_commander_banned_count: `3`",
                "candidate_copy_allowed_now: `false`",
                "Mana Vault",
                "Mana Crypt",
                "Dockside Extortionist",
                "Swiftfoot Boots",
                "Wishclaw Talisman",
                "rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_LIVE_RESEARCH_REPORT,
            [
                "Global Commander External Nonpayoff Expanded Source Candidate Reviewer",
                "expanded_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "reviewed_candidate_count: `24`",
                "miner_source_seed_allowed_count: `7`",
                "blocked_current_deck_count: `3`",
                "blocked_recycled_prior_seed_count: `14`",
                "Unbreakable Formation",
                "Orim's Chant",
                "Sword of the Animist",
                "rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_LIVE_RESEARCH_REPORT,
            [
                "Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "reviewed_seed_count: `7`",
                "seeded_role_count: `2`",
                "unseeded_target_role_count: `1`",
                "fresh_seeded_same_lane_cut_source_count: `0`",
                "blocked_recycled_seeded_cut_source_count: `31`",
                "unseeded_target_roles_remain_blocked:tutors_access",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_LIVE_RESEARCH_REPORT,
            [
                "Global Commander External Nonpayoff Seed Exhaustion Recovery Router",
                "external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review",
                "seeded_exhausted_role_count: `2`",
                "unseeded_role_count: `1`",
                "current_deck_negative_review_candidate_count: `3`",
                "prior_fresh_seeded_same_lane_cut_source_count: `0`",
                "Grand Abolisher",
                "Silence",
                "Arena of Glory",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR_LIVE_RESEARCH_REPORT,
            [
                "Global Commander External Nonpayoff Current Deck Negative Review Collector",
                "external_current_deck_negative_review_blocks_used_candidates",
                "current_deck_candidate_count: `3`",
                "usage_blocked_candidate_count: `1`",
                "seen_without_usage_count: `2`",
                "negative_review_cleared_count: `0`",
                "Grand Abolisher",
                "Silence",
                "Arena of Glory",
                "find_new_external_source_or_explicit_same_lane_replacement_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_MANUAL_NEGATIVE_TRACE_REVIEWER_LIVE_RESEARCH_REPORT,
            [
                "Global Commander External Nonpayoff Manual Negative Trace Reviewer",
                "external_nonpayoff_manual_negative_trace_review_blocks_current_deck_cuts",
                "manual_negative_review_cleared_count: `0`",
                "used_blocked_count: `1`",
                "static_silence_blocked_count: `1`",
                "land_lane_blocked_count: `1`",
                "Grand Abolisher",
                "Silence",
                "Arena of Glory",
                "find_new_external_source_or_explicit_same_lane_replacement_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_FOLLOWUP_LIVE_SOURCE_RESEARCH_EXPANDER_AFTER_MANUAL_TRACE_REPORT,
            [
                "Global Commander External Nonpayoff Followup Live Source Research Expander",
                "external_nonpayoff_followup_live_source_research_expanded_ready_for_local_review",
                "manual_negative_review_cleared_count: `0`",
                "previous_report_count: `14`",
                "cumulative_previous_candidate_name_count: `95`",
                "followup_candidate_count: `13`",
                "followup_ready_for_review_count: `11`",
                "Dolmen Gate",
                "Black Market Connections",
                "Deflecting Swat",
                "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_FOLLOWUP_LIVE_AFTER_MANUAL_TRACE_REPORT,
            [
                "Global Commander External Nonpayoff Expanded Source Candidate Reviewer",
                "expanded_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "reviewed_candidate_count: `13`",
                "miner_source_seed_allowed_count: `11`",
                "blocked_recycled_prior_seed_count: `2`",
                "candidate_copy_allowed_count: `0`",
                "Dolmen Gate",
                "Black Market Connections",
                "rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_FOLLOWUP_LIVE_AFTER_MANUAL_TRACE_REPORT,
            [
                "Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "reviewed_seed_count: `11`",
                "fresh_seeded_same_lane_cut_source_count: `0`",
                "blocked_recycled_seeded_cut_source_count: `47`",
                "unseeded_target_role_count: `0`",
                "Black Market Connections",
                "expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_FOLLOWUP_LIVE_AFTER_MANUAL_TRACE_REPORT,
            [
                "Global Commander External Nonpayoff Seed Exhaustion Recovery Router",
                "external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion",
                "seeded_exhausted_role_count: `3`",
                "current_deck_negative_review_candidate_count: `0`",
                "prior_blocked_recycled_seeded_cut_source_count: `47`",
                "force_access_selected_db_absent_count: `0`",
                "expand_external_nonpayoff_source_candidate_pool",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_EXPANDED_SOURCES_REPORT,
            [
                "Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "reviewed_seed_count: `22`",
                "seeded_role_count: `3`",
                "scanned_seeded_same_lane_source_count: `47`",
                "fresh_seeded_same_lane_cut_source_count: `0`",
                "blocked_recycled_seeded_cut_source_count: `47`",
                "candidate_copy_allowed_now: `false`",
                "expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_EXPANDED_SOURCES_REPORT,
            [
                "Global Commander External Nonpayoff Seed Exhaustion Recovery Router",
                "external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review",
                "current_deck_negative_review_candidate_count: `1`",
                "prior_blocked_recycled_seeded_cut_source_count: `47`",
                "candidate_copy_allowed_now: `false`",
                "Mana Vault",
                "collect_current_deck_negative_review_for_external_nonpayoff_candidates",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_CURRENT_DECK_NEGATIVE_REVIEW_COLLECTOR_EXPANDED_SOURCES_REPORT,
            [
                "Global Commander External Nonpayoff Current Deck Negative Review Collector",
                "external_current_deck_negative_review_blocks_used_candidates",
                "current_deck_candidate_count: `1`",
                "usage_blocked_candidate_count: `1`",
                "seen_without_usage_count: `0`",
                "not_seen_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "Mana Vault",
                "Usage | Exposure | Decisions",
                "find_new_external_source_or_explicit_same_lane_replacement_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_FOLLOWUP_SOURCE_CANDIDATE_EXPANDER_REPORT,
            [
                "Global Commander External Nonpayoff Followup Source Candidate Expander",
                "external_nonpayoff_followup_source_candidate_pool_expanded_ready_for_local_review",
                "previous_report_count: `4`",
                "cumulative_previous_candidate_name_count: `55`",
                "followup_candidate_count: `34`",
                "followup_ready_for_review_count: `34`",
                "candidate_copy_allowed_now: `false`",
                "Darksteel Plate",
                "Commander's Sphere",
                "Entomb",
                "all_prior_finder_reviewer_and_expander_candidates_are_recycled_and_blocked",
                "review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_EXPANDED_SOURCE_CANDIDATE_REVIEWER_FOLLOWUP_REPORT,
            [
                "Global Commander External Nonpayoff Expanded Source Candidate Reviewer",
                "expanded_external_source_candidates_reviewed_seed_ready_no_deck_action",
                "expander_ready_candidate_count: `34`",
                "reviewed_candidate_count: `34`",
                "miner_source_seed_allowed_count: `34`",
                "blocked_current_deck_count: `0`",
                "blocked_commander_banned_count: `0`",
                "blocked_recycled_prior_seed_count: `0`",
                "blocked_role_mismatch_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "Blacksmith's Skill",
                "Wayfarer's Bauble",
                "rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_REVIEWED_EXTERNAL_NONPAYOFF_SEEDED_CUT_SOURCE_MINER_FOLLOWUP_REPORT,
            [
                "Global Commander Reviewed External Nonpayoff Seeded Cut Source Miner",
                "reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission",
                "reviewed_seed_count: `34`",
                "seeded_role_count: `3`",
                "scanned_seeded_same_lane_source_count: `47`",
                "fresh_seeded_same_lane_cut_source_count: `0`",
                "blocked_recycled_seeded_cut_source_count: `47`",
                "candidate_copy_allowed_now: `false`",
                "expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_NONPAYOFF_SEED_EXHAUSTION_RECOVERY_ROUTER_FOLLOWUP_REPORT,
            [
                "Global Commander External Nonpayoff Seed Exhaustion Recovery Router",
                "external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion",
                "target_role_count: `3`",
                "seeded_exhausted_role_count: `3`",
                "current_deck_negative_review_candidate_count: `0`",
                "prior_blocked_recycled_seeded_cut_source_count: `47`",
                "candidate_copy_allowed_now: `false`",
                "expand_external_nonpayoff_source_candidate_pool",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_CUT_SOURCE_HYPOTHESIS_TRACE_COLLECTOR_REPORT,
            [
                "Global Commander Cut-Source Hypothesis Trace Collector",
                "cut_source_hypothesis_trace_blocks_used_hypotheses",
                "hypothesis_count: `8`",
                "usage_blocked_hypothesis_count: `6`",
                "seen_without_usage_count: `2`",
                "not_seen_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "mine_more_hypotheses_or_build_same_lane_proof",
                "Biotransference",
                "Trouble in Pairs",
                "Puresteel Paladin",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_CUT_HYPOTHESIS_SAME_LANE_PROOF_REPORT,
            [
                "Global Commander Cut-Hypothesis Same-Lane Proof",
                "cut_hypothesis_same_lane_proof_routes_to_more_mining",
                "hypothesis_count: `8`",
                "usage_blocked_hypothesis_count: `6`",
                "seen_without_usage_count: `2`",
                "not_seen_count: `0`",
                "explicit_same_lane_route_count: `0`",
                "incidental_role_overlap_count: `9`",
                "package_explicit_add_axes: `angels_demons_dragons_payoffs`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "mine_more_hypotheses_or_external_cut_source_research",
                "Biotransference",
                "Necropotence",
                "Trouble in Pairs",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_CUT_SOURCE_RESEARCH_PLAN_REPORT,
            [
                "Global Commander External Cut-Source Research Plan",
                "external_cut_source_research_plan_ready_no_deck_action",
                "hypothesis_count: `8`",
                "usage_blocked_hypothesis_count: `6`",
                "seen_without_usage_count: `2`",
                "explicit_same_lane_route_count: `0`",
                "external_source_count: `6`",
                "package_explicit_add_axes: `angels_demons_dragons_payoffs`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "collect_external_commander_reference_corpus_for_cut_candidates",
                "wizards_commander_brackets_2026_02_09",
                "edhrec_kaalia_current",
                "external_research_cannot_override_target_usage",
                "external_research_requires_negative_trace_review_first",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_REFERENCE_CORPUS_COLLECTOR_REPORT,
            [
                "Global Commander External Reference Corpus Collector",
                "external_reference_corpus_collected_no_cut_permission",
                "hypothesis_count: `8`",
                "source_count: `5`",
                "commander_public_decks_observed: `37936`",
                "filtered_midrange_sample_decks: `16`",
                "corpus_present_count: `3`",
                "corpus_absent_count: `5`",
                "usage_blocked_count: `6`",
                "seen_without_usage_count: `2`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "map_external_corpus_to_cut_policy_before_rerun_miner",
                "Necropotence",
                "Biotransference",
                "external_absence_cannot_override_target_usage",
                "external_corpus_supports_preserve_or_strict_same_lane_proof",
            ],
        )
    )
    checks.append(
        check_contains(
            GLOBAL_COMMANDER_SCOPE1_EXTERNAL_CORPUS_CUT_POLICY_MAPPER_REPORT,
            [
                "Global Commander External Corpus Cut Policy Mapper",
                "external_corpus_cut_policy_blocks_current_hypotheses",
                "policy_row_count: `8`",
                "excluded_from_rerun_miner_count: `6`",
                "held_for_negative_review_count: `2`",
                "rerun_miner_allowed_card_count: `0`",
                "candidate_copy_allowed_now: `false`",
                "value_safe_reclassification_allowed_now: `false`",
                "rerun_value_safe_cut_source_miner_with_external_policy_exclusions",
                "Biotransference",
                "Necropotence",
                "Trouble in Pairs",
                "exclude_from_rerun_miner_until_new_internal_evidence",
                "protect_from_rerun_miner_until_same_lane_or_equal_gate",
            ],
        )
    )

    historical = []
    for path, marker in HISTORICAL_BLOCKED_SURFACES.items():
        text = read(path)
        historical.append(
            {
                "path": rel(path),
                "exists": path.exists(),
                "marker": marker,
                "status": "pass" if path.exists() and marker in text else "fail",
            }
        )

    failures = [check for check in checks if check["status"] != "pass"]
    failures.extend(row for row in historical if row["status"] != "pass")
    warnings = [row for row in volatile_historical_reports if row["status"] != "pass"]
    return {
        "generated_at": utc_now(),
        "status": "pass" if not failures else "fail",
        "contract": rel(CONTRACT_DOC),
        "active_surfaces": checks,
        "historical_blocked_surfaces": historical,
        "volatile_historical_reports": volatile_historical_reports,
        "warnings": warnings,
        "failures": failures,
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Deckbuilding Contract Surface Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Contract: `{payload['contract']}`",
        "",
        "## Active Surfaces",
        "",
        "| Status | Path | Missing |",
        "| --- | --- | --- |",
    ]
    for row in payload["active_surfaces"]:
        missing = ", ".join(row.get("missing") or [])
        lines.append(f"| {row['status']} | `{row['path']}` | {missing} |")
    lines.extend(["", "## Historical Blocked Surfaces", "", "| Status | Path | Marker |", "| --- | --- | --- |"])
    for row in payload["historical_blocked_surfaces"]:
        lines.append(f"| {row['status']} | `{row['path']}` | `{row['marker']}` |")
    lines.extend(
        [
            "",
            "## Volatile Historical Reports",
            "",
            "| Status | Path | Reason | Missing |",
            "| --- | --- | --- | --- |",
        ]
    )
    for row in payload["volatile_historical_reports"]:
        missing = ", ".join(row.get("missing") or [])
        lines.append(f"| {row['status']} | `{row['path']}` | {row['reason']} | {missing} |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "deckbuilding_contract_surface_audit_20260629",
    )
    args = parser.parse_args()
    payload = build_audit()
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
