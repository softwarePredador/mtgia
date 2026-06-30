#!/usr/bin/env python3
"""Build and gate small Lorehold synergy packages against the current shell.

The package runner is intentionally isolated: it copies a source SQLite DB,
applies card swaps to the copied baseline deck, and delegates the actual comparison to
``lorehold_variant_battle_gate.py``. No source DB or PostgreSQL state is
mutated.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import signal
import shutil
import sqlite3
import subprocess
import sys
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import battle_rule_registry
from master_optimizer_common import normalize_name
from reviewed_battle_card_rules import DEFAULT_REVIEWED_RULES_PATH, load_reviewed_rule_rows


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
CANONICAL_SNAPSHOT = SCRIPT_DIR / "known_cards_canonical_snapshot.json"
DEFAULT_SOURCE_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))
DEFAULT_CUT_SAFETY_REPORT = REPORT_DIR / "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json"
DEFAULT_REGISTRY = REPORT_DIR / "lorehold_candidate_hypothesis_registry_20260626.json"
DEFAULT_RUNTIME_PACKAGE_PROPOSALS = (
    REPORT_DIR / "lorehold_runtime_gap_family_queue_20260628_v5_topdeck_damage_proposals.json"
)
DEFAULT_HIDDEN_RETREAT_RUNTIME_PACKAGE_PROPOSALS = (
    REPORT_DIR / "xmage_hidden_retreat_runtime_scope_20260628_v3_proposals.json"
)
DEFAULT_RUNTIME_PACKAGE_PROPOSAL_REPORTS = (
    DEFAULT_RUNTIME_PACKAGE_PROPOSALS,
    DEFAULT_HIDDEN_RETREAT_RUNTIME_PACKAGE_PROPOSALS,
)
DEFAULT_PRIOR_PACKAGE_REPORTS = (
    DEFAULT_CUT_SAFETY_REPORT,
    REPORT_DIR / "lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json",
    REPORT_DIR / "lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json",
    REPORT_DIR / "lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json",
    REPORT_DIR / "lorehold_mana_base_plateau_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json",
    REPORT_DIR / "lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json",
    REPORT_DIR / "lorehold_brass_bounty_confirm_matrix_20260628_v2_20260628_072000.json",
    REPORT_DIR / "lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json",
    REPORT_DIR / "lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000.json",
    REPORT_DIR / "lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json",
    REPORT_DIR / "lorehold_mana_vault_gate_20260628_v1_20260628_092000.json",
    REPORT_DIR / "lorehold_mana_vault_gate_after_ramp_runtime_fix_20260628_v1_20260628_102000.json",
    REPORT_DIR / "lorehold_mana_vault_natural_confirmation_after_forced_20260628_v1_20260628_100237.json",
    REPORT_DIR / "lorehold_protection_ready_gate_20260628_v1_20260628_095000.json",
    REPORT_DIR / "lorehold_profiled_cut_benchmark_matrix_20260628_v1_20260628_083628.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v2_20260628_085703.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v3_20260628_090640.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_20260628_091321.json",
    REPORT_DIR
    / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v4b_witch_confirm_20260628_091458.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v5_20260628_092712.json",
    REPORT_DIR / "lorehold_profiled_cut_family_benchmark_matrix_20260628_v6_20260628_093001.json",
    REPORT_DIR / "lorehold_forced_exposure_probe_decision_20260630.json",
    REPORT_DIR / "lorehold_forced_signal_natural_confirm_decision_20260630.json",
    REPORT_DIR / "lorehold_profiled_cut_benchmark_gate_decision_20260630.json",
)


PACKAGE_DEFINITIONS: dict[str, dict[str, Any]] = {
    "one_ring_burden_reset": {
        "hypothesis": (
            "The Mind Stone can reset The One Ring burden counters after harness; "
            "test whether that draw engine is worth a non-core utility/ramp slot."
        ),
        "adds": ["The One Ring"],
        "cuts": ["Bender's Waterskin"],
    },
    "one_ring_protection_draw_cut_squelcher": {
        "family": "draw_protection",
        "hypothesis": (
            "The One Ring may buy the exact turn seed 20260625 lacks while adding "
            "repeatable draw. This preserves the three-mana ramp shell and cuts "
            "the narrower anti-counter creature instead."
        ),
        "adds": ["The One Ring"],
        "cuts": ["Hexing Squelcher"],
    },
    "birgi_spellchain_cut_squelcher": {
        "family": "spellchain_mana",
        "hypothesis": (
            "Birgi adds red mana on every spell cast, which should help Lorehold "
            "chain miracle spells without cutting the expensive spell package."
        ),
        "adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
        "cuts": ["Hexing Squelcher"],
    },
    "birgi_spellchain_cut_waterskin": {
        "family": "spellchain_mana",
        "hypothesis": (
            "Birgi may outperform a three-mana mana rock because the deck often "
            "casts several spells in a turn after a miracle setup."
        ),
        "adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
        "cuts": ["Bender's Waterskin"],
    },
    "birgi_spellchain_cut_jeskas_will": {
        "family": "spellchain_mana",
        "hypothesis": (
            "Birgi tests the same early-mana/spell-chain job without cutting the "
            "now-protected medallions, Bender's Waterskin, or Victory Chimes. "
            "Jeska's Will is the comparison slot because it is a powerful but "
            "one-shot mana burst rather than a repeatable cast-trigger engine."
        ),
        "adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"],
        "cuts": ["Jeska's Will"],
    },
    "birgi_seething_chain_cut_medallions": {
        "family": "spellchain_mana",
        "hypothesis": (
            "The loss classifier shows mana/spell-volume failures under pressure. "
            "This imports the narrow 615 ritual lane while preserving Dawn's Truce, "
            "Teferi's Protection, High Noon, Hexing Squelcher, Storm Herd, and the "
            "three-mana ramp shell; it tests whether cast-trigger mana plus a "
            "one-shot ritual beats static red/white medallion discounts."
        ),
        "adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty", "Seething Song"],
        "cuts": ["Pearl Medallion", "Ruby Medallion"],
    },
    "seething_song_cut_fellwar_stone": {
        "family": "spellchain_mana",
        "hypothesis": (
            "Seething Song tests whether a ritual burst converts the current "
            "mana/spell bottleneck faster than a generic two-mana rock while "
            "preserving all cut-safety-protected ramp slots."
        ),
        "adds": ["Seething Song"],
        "cuts": ["Fellwar Stone"],
    },
    "storm_kiln_artist_cut_arcane_signet": {
        "family": "spellchain_mana",
        "hypothesis": (
            "Storm-Kiln Artist can turn every instant or sorcery into treasure. "
            "This tests a repeatable spell-mana engine over the most generic "
            "untested rock, without touching medallions, Bender's Waterskin, "
            "Victory Chimes, or the finisher package."
        ),
        "adds": ["Storm-Kiln Artist"],
        "cuts": ["Arcane Signet"],
    },
    "mana_vault_fast_mana_cut_arcane_signet": {
        "family": "fast_mana",
        "hypothesis": (
            "Mana Vault is legal, battle-ready fast mana and appears in multiple "
            "Lorehold variants. This tests whether one-mana colorless burst "
            "accelerates commander and expensive spell windows more than Arcane "
            "Signet's colored fixing, without cutting protected medallions, "
            "Bender's Waterskin, Victory Chimes, or Jeska's Will."
        ),
        "adds": ["Mana Vault"],
        "cuts": ["Arcane Signet"],
    },
    "brass_bounty_cut_boros_signet": {
        "family": "spellchain_mana",
        "hypothesis": (
            "Brass's Bounty is shared by six Lorehold variants and now has a "
            "reviewed runtime model that creates Treasure equal to lands "
            "controlled. This tests whether a late ritual/treasure burst is "
            "better than the least-blocked two-mana Boros rock without cutting "
            "Sol Ring, Bender's Waterskin, medallions, Victory Chimes, or the "
            "protection/finisher shell."
        ),
        "adds": ["Brass's Bounty"],
        "cuts": ["Boros Signet"],
    },
    "runaway_steamkin_cut_talisman": {
        "family": "spellchain_mana",
        "hypothesis": (
            "Runaway Steam-Kin is a low-curve red spell mana engine. It tests "
            "whether repeated red-spell turns create more conversion pressure "
            "than a generic two-mana Boros rock while preserving the protected "
            "three-mana ramp and medallion shell."
        ),
        "adds": ["Runaway Steam-Kin"],
        "cuts": ["Talisman of Conviction"],
    },
    "gamble_approach_access_cut_creative": {
        "family": "tutor_access",
        "hypothesis": (
            "The loss classifier shows topdeck/miracle turns failing to find or "
            "recast Approach before combat pressure. Gamble tests a cheap universal "
            "tutor over a five-mana demonstrate/free-cast slot while preserving the "
            "existing protection, ramp, medallion, Bender's Waterskin, Hexing "
            "Squelcher, and Storm Herd shell."
        ),
        "adds": ["Gamble"],
        "cuts": ["Creative Technique"],
        "allow_miracle_core_cuts": True,
    },
    "gamble_access_cut_thor": {
        "family": "tutor_access",
        "hypothesis": (
            "Gamble improved weak seeds when it cut Creative Technique but broke "
            "seed 42. This retest keeps the modeled free-cast slot and instead "
            "cuts Thor, whose local runtime rule has natural exposure but no deck "
            "win-rate lift yet, while preserving Dawn's Truce, Teferi's Protection, "
            "High Noon, Hexing Squelcher, Storm Herd, medallions, Bender's Waterskin, "
            "and the three-mana ramp shell."
        ),
        "adds": ["Gamble"],
        "cuts": ["Thor, God of Thunder"],
        "allow_miracle_core_cuts": True,
    },
    "enlightened_engine_access_cut_thor": {
        "family": "tutor_access",
        "hypothesis": (
            "Enlightened Tutor tests a lower-risk access line than Gamble: it cannot "
            "find Approach, but it can put artifact/enchantment engines on top for "
            "Lorehold and miracle setup without random discard. Thor is the cut for "
            "the same modeled-not-proven reason as the Gamble retest."
        ),
        "adds": ["Enlightened Tutor"],
        "cuts": ["Thor, God of Thunder"],
        "allow_miracle_core_cuts": True,
    },
    "gamble_access_benchmark_cut_land_tax": {
        "family": "tutor_access_benchmark",
        "hypothesis": (
            "The tutor cut model found no seed-safe direct tutor swap, but ranked "
            "Land Tax as the highest same-access benchmark. This is not a promotion "
            "candidate by itself: it tests whether Gamble's any-card access can "
            "outperform Land Tax's upkeep basic-land access without repeating the "
            "failed Thor or Creative Technique cuts."
        ),
        "adds": ["Gamble"],
        "cuts": ["Land Tax"],
        "cut_safety_override_reason": (
            "same-access benchmark required by lorehold_tutor_cut_model_20260627_v1"
        ),
    },
    "enlightened_access_benchmark_cut_land_tax": {
        "family": "tutor_access_benchmark",
        "hypothesis": (
            "The tutor cut model found no seed-safe direct tutor swap, but ranked "
            "Land Tax as the highest same-access benchmark. Enlightened Tutor is "
            "the lower-randomness comparison: it cannot find Approach directly, "
            "but it can put artifact/enchantment engines on top for Lorehold's "
            "miracle draw window while preserving the failed Thor and Creative "
            "Technique slots."
        ),
        "adds": ["Enlightened Tutor"],
        "cuts": ["Land Tax"],
        "cut_safety_override_reason": (
            "same-access benchmark required by lorehold_tutor_cut_model_20260627_v1"
        ),
    },
    "galvanoth_topdeck_freecast": {
        "family": "topdeck_freecast",
        "hypothesis": (
            "Galvanoth turns topdeck setup into free upkeep casts for the same "
            "expensive instant/sorcery package Lorehold wants to miracle."
        ),
        "adds": ["Galvanoth"],
        "cuts": ["Bender's Waterskin"],
    },
    "galvanoth_topdeck_freecast_cut_squelcher": {
        "family": "topdeck_freecast",
        "hypothesis": (
            "Galvanoth was aggregate-positive but failed the seed-42 success case "
            "when it cut Bender's Waterskin. This retest preserves the ramp shell "
            "and cuts the narrower anti-counter creature instead."
        ),
        "adds": ["Galvanoth"],
        "cuts": ["Hexing Squelcher"],
    },
    "galvanoth_topdeck_freecast_cut_chimes": {
        "family": "topdeck_freecast",
        "hypothesis": (
            "Galvanoth was the only aggregate-positive topdeck package, but the "
            "Bender's Waterskin cut broke the seed-42 success case and the "
            "Hexing Squelcher cut was worse. This retest preserves both colored "
            "ramp and anti-counter pressure, cutting the more generic colorless "
            "three-mana ramp slot instead."
        ),
        "adds": ["Galvanoth"],
        "cuts": ["Victory Chimes"],
    },
    "galvanoth_topdeck_freecast_cut_thor": {
        "family": "topdeck_freecast",
        "hypothesis": (
            "Galvanoth is the current topdeck/freecast lane with a weak-seed "
            "signal but bad prior cuts. This retest preserves Bender's Waterskin, "
            "Hexing Squelcher, Victory Chimes, the protection shell, and the "
            "medallions, cutting Thor only as a same-plan diagnostic because "
            "Thor has local runtime exposure but no proven win-rate lift yet."
        ),
        "adds": ["Galvanoth"],
        "cuts": ["Thor, God of Thunder"],
        "allow_miracle_core_cuts": True,
    },
    "pg245_verge_rangers_topdeck_land_cut_waterskin": {
        "family": "topdeck_play",
        "hypothesis": (
            "PG245 gives Verge Rangers an executable XMage-backed topdeck land "
            "play model. This same-lane diagnostic challenges Bender's Waterskin "
            "only because both occupy the three-mana early-mana/topdeck support "
            "slot, while preserving the expensive miracle spell package."
        ),
        "adds": ["Verge Rangers"],
        "cuts": ["Bender's Waterskin"],
        "cut_safety_override_reason": (
            "PG245 same-lane topdeck_play/ramp benchmark; isolated candidate only"
        ),
    },
    "brainstone_topdeck_miracle": {
        "family": "topdeck_setup",
        "hypothesis": (
            "Brainstone is another cheap topdeck manipulation artifact that can "
            "turn the first draw into a planned miracle window."
        ),
        "adds": ["Brainstone"],
        "cuts": ["Bender's Waterskin"],
    },
    "brainstone_topdeck_miracle_cut_squelcher": {
        "family": "topdeck_setup",
        "hypothesis": (
            "Brainstone failed when it cut Bender's Waterskin; this variant "
            "preserves ramp and tests whether a cheap one-shot topdeck engine "
            "can help seed 7 find the Library/topdeck conversion line."
        ),
        "adds": ["Brainstone"],
        "cuts": ["Hexing Squelcher"],
    },
    "faithless_looting_squee_enabler": {
        "family": "discard_rummage_recursion",
        "hypothesis": (
            "Faithless Looting gives the Squee shell a cheap, executable discard "
            "outlet plus card flow, testing whether the proven Squee return loop "
            "needs more ways to put Squee into the graveyard before Lorehold's "
            "topdeck/miracle engine can convert."
        ),
        "adds": ["Faithless Looting"],
        "cuts": ["Hexing Squelcher"],
    },
    "penance_topdeck_protection_cut_squelcher": {
        "family": "topdeck_protection",
        "hypothesis": (
            "Penance gives an executable hand-to-library topdeck line plus combat "
            "damage prevention. It tests topdeck consistency without relying on "
            "land-only placeholder rules such as The Biblioplex or Mirrorpool."
        ),
        "adds": ["Penance"],
        "cuts": ["Hexing Squelcher"],
    },
    "penance_runtime_topdeck_cut_promise": {
        "family": "topdeck_protection",
        "hypothesis": (
            "Penance is retested after the battle runtime learned to use "
            "hand-to-library activations proactively as Lorehold miracle setup, "
            "not only as a lethal-combat damage shield. This avoids the locked "
            "Hexing Squelcher cut and measures whether the new sequencing can "
            "replace one five-mana wipe/political spell without reducing the "
            "known topdeck engine."
        ),
        "adds": ["Penance"],
        "cuts": ["Promise of Loyalty"],
        "allow_miracle_core_cuts": True,
    },
    "hidden_retreat_stack_damage_topdeck_cut_promise": {
        "family": "topdeck_protection",
        "hypothesis": (
            "Hidden Retreat now has a local XMage-backed runtime proposal and "
            "responds to damaging instant/sorcery spells by putting a hand card "
            "on top of the library and preventing that spell's damage. This "
            "isolated overlay test measures whether the stack-damage shield plus "
            "miracle-topdeck setup beats the five-mana Promise of Loyalty pressure "
            "slot without cutting ramp, medallions, Squee, topdeck engines, or the "
            "known protection shell."
        ),
        "adds": ["Hidden Retreat"],
        "cuts": ["Promise of Loyalty"],
        "allow_miracle_core_cuts": True,
    },
    "ghostly_prison_pressure_cut_squelcher": {
        "family": "pressure_absorber",
        "hypothesis": (
            "Ghostly Prison directly attacks the seed-20260625 failure mode: "
            "the deck can put Approach on top but dies to combat pressure before "
            "conversion. This retest avoids the prior bad High Noon cut."
        ),
        "adds": ["Ghostly Prison"],
        "cuts": ["Hexing Squelcher"],
    },
    "boros_charm_pressure_cut_fated": {
        "family": "pressure_absorber",
        "hypothesis": (
            "Boros Charm appears across the stronger Lorehold variants as cheap "
            "instant-speed protection/pressure absorption. This same-lane triage "
            "tests whether lowering a five-mana pressure-response slot into a "
            "two-mana modal protection spell improves the life-zero combat "
            "failures without cutting ramp, topdeck engines, High Noon, Hexing "
            "Squelcher, Storm Herd, or the protection shell."
        ),
        "adds": ["Boros Charm"],
        "cuts": ["Fated Clash"],
        "allow_miracle_core_cuts": True,
    },
    "boros_charm_pressure_cut_avatar_wrath": {
        "family": "pressure_absorber",
        "hypothesis": (
            "Boros Charm previously failed when it cut protected Fated Clash. "
            "This retest keeps Fated Clash, Dawn's Truce, Hexing Squelcher, and "
            "the ramp shell intact, using another pressure/protection lane slot "
            "as the comparison instead. This is an explicit same-lane high-CMC "
            "spell benchmark, not a free cut of the miracle payoff package."
        ),
        "adds": ["Boros Charm"],
        "cuts": ["Avatar's Wrath"],
        "allow_miracle_core_cuts": True,
    },
    "perch_protection_cut_avatar_wrath": {
        "family": "pressure_absorber",
        "hypothesis": (
            "Perch Protection is present in the two strongest non-607 variants "
            "and has active local battle rules. It tests a same-lane protection "
            "upgrade over Avatar's Wrath while preserving Dawn's Truce, Fated "
            "Clash, Hexing Squelcher, High Noon, medallions, Storm Herd, and Thor."
        ),
        "adds": ["Perch Protection"],
        "cuts": ["Avatar's Wrath"],
        "allow_miracle_core_cuts": True,
    },
    "akromas_will_cut_avatar_wrath": {
        "family": "pressure_absorber",
        "hypothesis": (
            "Akroma's Will is a 614 protection/finisher bridge with active local "
            "battle rules. It challenges Avatar's Wrath without touching the "
            "locked protection shell or the medallion/topdeck engine."
        ),
        "adds": ["Akroma's Will"],
        "cuts": ["Avatar's Wrath"],
        "allow_miracle_core_cuts": True,
    },
    "silence_cut_avatar_wrath": {
        "family": "spell_protection",
        "hypothesis": (
            "Silence is shared by 614/615 and protects the decisive Lorehold or "
            "Approach turn at one mana. This tests whether cheap proactive stack "
            "protection beats a slower protection spell without cutting locked cards."
        ),
        "adds": ["Silence"],
        "cuts": ["Avatar's Wrath"],
        "allow_miracle_core_cuts": True,
    },
    "gods_willing_commander_shield_cut_promise": {
        "family": "targeted_commander_protection",
        "hypothesis": (
            "After the runtime learned targeted protection responses, Gods "
            "Willing tests the cheapest 616 commander shield against the seed-7 "
            "failure mode where Lorehold died to targeted removal with one mana "
            "available. Promise of Loyalty is the pressure-lane comparison slot: "
            "it is a five-mana sorcery cleanup spell already challenged by the "
            "Ghostly Prison pressure test, while this keeps Mother/Giver, Dawn's "
            "Truce, High Noon, topdeck engines, ramp, and the expensive win "
            "package intact."
        ),
        "adds": ["Gods Willing"],
        "cuts": ["Promise of Loyalty"],
        "allow_miracle_core_cuts": True,
    },
    "sejiri_shelter_commander_shield_cut_promise": {
        "family": "targeted_commander_protection",
        "hypothesis": (
            "Sejiri Shelter carries the same targeted protection rule as Gods "
            "Willing, but costs two mana and is currently evaluated by the local "
            "runtime as the spell face rather than as a flexible MDFC land. This "
            "benchmark checks whether the extra shield density is still useful "
            "when compared against the same five-mana pressure cleanup slot."
        ),
        "adds": ["Sejiri Shelter // Sejiri Glacier"],
        "cuts": ["Promise of Loyalty"],
        "allow_miracle_core_cuts": True,
    },
    "dragon_rage_channeler_cut_scarlet_witch": {
        "family": "topdeck_filter",
        "hypothesis": (
            "Dragon's Rage Channeler is a low-cost 614 topdeck/filter engine with "
            "active local battle rules. It targets seed 7's missing early engine "
            "by challenging The Scarlet Witch, a materialization-sensitive slot."
        ),
        "adds": ["Dragon's Rage Channeler"],
        "cuts": ["The Scarlet Witch"],
        "allow_miracle_core_cuts": True,
    },
    "grand_abolisher_cut_mother_of_runes": {
        "family": "spell_protection",
        "hypothesis": (
            "Grand Abolisher protects the whole decisive turn and appears in 615. "
            "Mother of Runes is the same-creature-protection comparison slot, so "
            "this is a risky same-lane test rather than a generic support cut."
        ),
        "adds": ["Grand Abolisher"],
        "cuts": ["Mother of Runes"],
    },
    "reprieve_cut_avatar_wrath": {
        "family": "spell_protection",
        "hypothesis": (
            "Reprieve is a 615 tempo/protection card with active local battle rules. "
            "It can buy a turn and draw without cutting cards already locked by "
            "the seed-42 protection pattern."
        ),
        "adds": ["Reprieve"],
        "cuts": ["Avatar's Wrath"],
        "allow_miracle_core_cuts": True,
    },
    "angel_grace_life_floor_cut_dawn": {
        "family": "life_floor_protection",
        "hypothesis": (
            "The loss classifier shows early life-zero deaths even when the deck "
            "sometimes finds topdeck or Approach setup. Angel's Grace is a one-mana "
            "life-floor effect with executable runtime rules; this tests a same-lane "
            "protection swap over Dawn's Truce without cutting ramp, High Noon, "
            "Hexing Squelcher, or Storm Herd."
        ),
        "adds": ["Angel's Grace"],
        "cuts": ["Dawn's Truce"],
    },
    "primal_amulet_spell_engine": {
        "family": "cost_reduce_copy",
        "hypothesis": (
            "Primal Amulet reduces instant/sorcery costs and can transform into "
            "a spell-copying mana land, matching the deck's expensive spell plan."
        ),
        "adds": ["Primal Amulet // Primal Wellspring"],
        "cuts": ["Bender's Waterskin"],
    },
    "chandra_copy_engine": {
        "family": "spell_copy",
        "hypothesis": (
            "Chandra, Hope's Beacon copies the first instant or sorcery each turn "
            "and can add mana, so it may turn one miracle spell into a win turn."
        ),
        "adds": ["Chandra, Hope's Beacon"],
        "cuts": ["Bender's Waterskin"],
    },
    "arcane_bombardment_engine": {
        "family": "spell_copy_recursion",
        "hypothesis": (
            "Arcane Bombardment rewards repeated instant/sorcery casting by "
            "copying graveyard spells, which should scale with Lorehold chains."
        ),
        "adds": ["Arcane Bombardment"],
        "cuts": ["Bender's Waterskin"],
    },
    "past_in_flames_recast": {
        "family": "graveyard_recast",
        "hypothesis": (
            "Past in Flames turns the graveyard of used instant/sorcery cards "
            "into a second spell chain without removing a miracle payoff."
        ),
        "adds": ["Past in Flames"],
        "cuts": ["Bender's Waterskin"],
    },
    "radiant_scrollwielder_cut_scarlet_witch": {
        "family": "graveyard_recursion",
        "hypothesis": (
            "Radiant Scrollwielder tests the 614 recursion/lifegain bridge: it "
            "turns a used instant/sorcery into a same-turn recast while giving "
            "all controlled instant/sorcery spells lifelink."
        ),
        "adds": ["Radiant Scrollwielder"],
        "cuts": ["The Scarlet Witch"],
        "allow_miracle_core_cuts": True,
    },
    "volcanic_recursion_cut_pinnacle": {
        "family": "graveyard_recursion_benchmark",
        "hypothesis": (
            "The recursion cut model protects Squee, Farewell, Furygale Flocking, "
            "and Mizzix's Mastery. Volcanic Vision over Pinnacle Monk is the first "
            "non-Squee same-lane benchmark: it trades a low-exposure ETB recursion "
            "engine for a high-cost instant/sorcery recursion spell with opponent "
            "creature damage annotation."
        ),
        "adds": ["Volcanic Vision"],
        "cuts": ["Pinnacle Monk // Mystic Peak"],
        "allow_miracle_core_cuts": True,
        "cut_safety_override_reason": (
            "preflight benchmark required by lorehold_recursion_cut_model_20260627_v1"
        ),
    },
    "austere_command_wipe_over_emeria_tradeoff": {
        "family": "pressure_reset_tradeoff",
        "hypothesis": (
            "Austere Command is a flexible board reset with active runtime rules, "
            "but Emeria's Call now has measured token/protection exposure. This "
            "gate is therefore an explicit wipe-over-rebuild tradeoff: it must "
            "prove that extra board-reset control beats losing Emeria's rebuild "
            "tokens, protection window, and miracle hit density."
        ),
        "adds": ["Austere Command"],
        "cuts": ["Emeria's Call // Emeria, Shattered Skyclave"],
        "allow_miracle_core_cuts": True,
    },
    "past_in_flames_cut_squelcher": {
        "family": "graveyard_recast",
        "hypothesis": (
            "Past in Flames may be strongest if it replaces narrow anti-counter "
            "pressure while preserving the deck's three-mana ramp artifact."
        ),
        "adds": ["Past in Flames"],
        "cuts": ["Hexing Squelcher"],
    },
    "past_overmaster_spellchain": {
        "family": "graveyard_recast_protection",
        "hypothesis": (
            "Past in Flames plus Overmaster combines the winning recast package "
            "with the best strategic-engine improvement from the broad triage."
        ),
        "adds": ["Past in Flames", "Overmaster"],
        "cuts": ["Bender's Waterskin", "Hexing Squelcher"],
    },
    "copy_stack_package": {
        "family": "spell_copy",
        "hypothesis": (
            "A compact copy package should make the deck's expensive miracle "
            "spells matter more without replacing the payoff suite itself."
        ),
        "adds": ["Reverberate", "Return the Favor", "Flare of Duplication"],
        "cuts": ["Hexing Squelcher", "Bender's Waterskin", "Victory Chimes"],
    },
    "overmaster_protect_draw": {
        "family": "spell_protection",
        "hypothesis": (
            "Overmaster protects the next key instant or sorcery and replaces "
            "itself, so it may be better than narrow anti-counter pressure."
        ),
        "adds": ["Overmaster"],
        "cuts": ["Hexing Squelcher"],
    },
    "overmaster_protect_draw_cut_tibalts_trickery": {
        "family": "spell_protection",
        "hypothesis": (
            "Overmaster protects a decisive instant or sorcery and replaces "
            "itself. This tests the spell-protection lane while keeping Hexing "
            "Squelcher and the known protection shell intact, comparing against "
            "a swingy protection/counter slot instead."
        ),
        "adds": ["Overmaster"],
        "cuts": ["Tibalt's Trickery"],
    },
    "lapse_approach_topdeck_cut_tibalts_trickery": {
        "family": "approach_topdeck_combo",
        "hypothesis": (
            "Lapse of Certainty is an external Lorehold/Approach line: counter "
            "the first Approach of the Second Sun and put it on top, then use "
            "Lorehold's first-draw miracle window for the second cast. Tibalt's "
            "Trickery is the comparison slot because it is the existing swingy "
            "counter/protection card."
        ),
        "adds": ["Lapse of Certainty"],
        "cuts": ["Tibalt's Trickery"],
    },
    "valakut_hand_filter_cut_big_score": {
        "family": "hand_filter_benchmark",
        "hypothesis": (
            "The hand-filter cut model ranked Valakut Awakening over Big Score "
            "as the first benchmark: Valakut has measured hand-filter exposure "
            "and a verified MDFC rule, while Big Score is the least-exposed "
            "visible protected cut but still provides discard, draw, and Treasure. "
            "This is an explicit hand-filter-over-ramp tradeoff, not a free cut."
        ),
        "adds": ["Valakut Awakening // Valakut Stoneforge"],
        "cuts": ["Big Score"],
        "allow_miracle_core_cuts": True,
        "cut_safety_override_reason": (
            "preflight benchmark required by lorehold_hand_filter_cut_model_20260627_v1"
        ),
    },
    "wheel_hand_filter_cut_big_score": {
        "family": "hand_filter_benchmark",
        "hypothesis": (
            "After Valakut over Big Score failed, the prior-aware hand-filter cut "
            "model ranked Wheel of Fortune as the next exact benchmark. Wheel has "
            "verified multiplayer discard/draw runtime and strong Lorehold variant "
            "exposure, but this remains an explicit wheel-over-ramp tradeoff because "
            "Big Score provides discard, draw, and Treasure."
        ),
        "adds": ["Wheel of Fortune"],
        "cuts": ["Big Score"],
        "allow_miracle_core_cuts": True,
        "cut_safety_override_reason": (
            "preflight benchmark required by lorehold_hand_filter_cut_model_20260627_v2_prior_aware"
        ),
    },
    "guttersnipe_spell_payoff_cut_prismari": {
        "family": "spellcast_payoff",
        "hypothesis": (
            "Guttersnipe is present in Lorehold variants 615/616 and gives direct "
            "multiplayer damage on every instant or sorcery. This tests whether "
            "a lower-curve spell payoff converts miracle/topdeck turns better "
            "than Prismari Pianist without cutting the protected ramp, pressure, "
            "or finisher shell."
        ),
        "adds": ["Guttersnipe"],
        "cuts": ["Prismari Pianist"],
        "allow_miracle_core_cuts": True,
    },
    "pg245_twinflame_damage_payoff_cut_thor": {
        "family": "static_damage_modifier",
        "hypothesis": (
            "PG245 gives Twinflame Tyrant an executable XMage-backed static "
            "damage-doubling model. This is a same-mana-value damage payoff "
            "diagnostic over Thor, not a promotion, because prior Thor cuts failed "
            "when the replacement was not a direct damage payoff."
        ),
        "adds": ["Twinflame Tyrant"],
        "cuts": ["Thor, God of Thunder"],
        "allow_miracle_core_cuts": True,
        "cut_safety_override_reason": (
            "PG245 same-slot damage payoff benchmark; isolated candidate only"
        ),
    },
    "monastery_mentor_spell_tokens_cut_prismari": {
        "family": "spellcast_payoff",
        "hypothesis": (
            "Monastery Mentor is present in Lorehold variant 616 and turns each "
            "noncreature spell into a growing board. This checks whether a token "
            "payoff survives combat pressure while converting Lorehold's miracle "
            "spell volume better than Prismari Pianist."
        ),
        "adds": ["Monastery Mentor"],
        "cuts": ["Prismari Pianist"],
        "allow_miracle_core_cuts": True,
    },
    "young_pyromancer_spell_tokens_cut_prismari": {
        "family": "spellcast_payoff",
        "hypothesis": (
            "Young Pyromancer is present in Lorehold variant 616 and creates board "
            "presence from instant/sorcery casts at two mana. This tests the same "
            "payoff lane at the lowest curve point while leaving the known topdeck "
            "and protection shell untouched."
        ),
        "adds": ["Young Pyromancer"],
        "cuts": ["Prismari Pianist"],
        "allow_miracle_core_cuts": True,
    },
    "ghostly_prison_pressure_cut_promise": {
        "family": "pressure_absorber",
        "hypothesis": (
            "Ghostly Prison previously failed when it cut protected Hexing "
            "Squelcher. This retest keeps Hexing Squelcher and Fated Clash, then "
            "checks whether a static attack tax is better than a slower pressure "
            "cleanup spell against the combat-pressure deaths. This is an "
            "explicit pressure-lane benchmark, not a generic cut of the big-spell "
            "miracle plan."
        ),
        "adds": ["Ghostly Prison"],
        "cuts": ["Promise of Loyalty"],
        "allow_miracle_core_cuts": True,
    },
    "boseiju_spell_protection_land": {
        "family": "spell_protection_land",
        "hypothesis": (
            "Boseiju, Who Shelters All protects decisive instant/sorcery casts "
            "from counters while preserving land count."
        ),
        "adds": ["Boseiju, Who Shelters All"],
        "cuts": ["Reliquary Tower"],
    },
    "plateau_timing_upgrade_cut_radiant_summit": {
        "family": "mana_base",
        "hypothesis": (
            "The deterministic mana-base validator marks Plateau over Radiant "
            "Summit as a strict Boros-source timing upgrade: it preserves red "
            "and white access, keeps land count unchanged, and removes a "
            "conditional tapped dual without cutting fetches or utility lands."
        ),
        "adds": ["Plateau"],
        "cuts": ["Radiant Summit"],
        "cut_safety_override_reason": (
            "Allowed only by lorehold_mana_base_validator_20260627_v1: "
            "preflight_land_swap_ready with red_source_delta=0, "
            "white_source_delta=0, and etb_score_delta=+2."
        ),
    },
    "plateau_timing_upgrade_cut_turbulent_steppe": {
        "family": "mana_base",
        "hypothesis": (
            "After Plateau over Radiant Summit failed the real gate, the "
            "mana-base validator still marks Plateau over Turbulent Steppe as "
            "a separate strict timing upgrade: it preserves red and white "
            "sources, keeps land count unchanged, and removes a late-game-only "
            "conditional tapped dual without cutting fetches or utility lands."
        ),
        "adds": ["Plateau"],
        "cuts": ["Turbulent Steppe"],
        "cut_safety_override_reason": (
            "Allowed only by lorehold_mana_base_validator_20260627_v2_plateau_rejected: "
            "preflight_land_swap_ready with red_source_delta=0, "
            "white_source_delta=0, etb_score_delta=+2, and no prior negative "
            "exact package."
        ),
    },
    "biblioplex_topdeck_land": {
        "family": "topdeck_land",
        "hypothesis": (
            "The Biblioplex gives a land-slot instant/sorcery topdeck selection "
            "tool for late games where Lorehold has a large hand."
        ),
        "adds": ["The Biblioplex"],
        "cuts": ["Reliquary Tower"],
    },
    "mirrorpool_spellcopy_land": {
        "family": "spell_copy_land",
        "hypothesis": (
            "Mirrorpool uses a land slot to copy a decisive instant or sorcery, "
            "testing whether colorless utility is worth more than hand size."
        ),
        "adds": ["Mirrorpool"],
        "cuts": ["Reliquary Tower"],
    },
    "core_challenge_dance_over_storm": {
        "family": "payoff_challenge",
        "hypothesis": (
            "Dance with Calamity is an expensive sorcery payoff that may produce "
            "more immediate wins than Storm Herd when miracle makes it cheap."
        ),
        "adds": ["Dance with Calamity"],
        "cuts": ["Storm Herd"],
        "allow_miracle_core_cuts": True,
    },
    "core_challenge_aetherflux_over_storm": {
        "family": "payoff_challenge",
        "hypothesis": (
            "Aetherflux Reservoir may convert Lorehold's spell-chain turns into "
            "a deterministic life-gain and 50-damage finish while preserving the "
            "expensive instant/sorcery package outside the Storm Herd slot."
        ),
        "adds": ["Aetherflux Reservoir"],
        "cuts": ["Storm Herd"],
        "allow_miracle_core_cuts": True,
    },
    "core_challenge_past_over_tragic": {
        "family": "payoff_challenge",
        "hypothesis": (
            "Past in Flames may be a stronger spell-chain payoff than a generic "
            "five-mana cleanup sorcery in the current shell."
        ),
        "adds": ["Past in Flames"],
        "cuts": ["Tragic Arrogance"],
        "allow_miracle_core_cuts": True,
    },
    "etb_tutor_blink": {
        "hypothesis": (
            "The Mind Stone blink becomes materially stronger when it can reuse "
            "creature tutors without cutting Lorehold's high-value spell payoffs."
        ),
        "adds": ["Imperial Recruiter", "Recruiter of the Guard", "Ranger-Captain of Eos"],
        "cuts": ["Bender's Waterskin", "Victory Chimes", "Hexing Squelcher"],
    },
    "sun_titan_blink_value": {
        "hypothesis": (
            "Sun Titan plus The Mind Stone creates repeatable permanent recursion "
            "for the deck's cheap artifacts, protection, and engines without "
            "removing expensive instant/sorcery miracle payoffs."
        ),
        "adds": ["Sun Titan"],
        "cuts": ["Bender's Waterskin"],
    },
    "sun_titan_cut_chimes": {
        "hypothesis": (
            "Sun Titan may be better than a multiplayer mana artifact if the "
            "recursion package offsets the lost ramp."
        ),
        "adds": ["Sun Titan"],
        "cuts": ["Victory Chimes"],
    },
    "sun_titan_cut_squelcher": {
        "hypothesis": (
            "Sun Titan may be better than a narrow anti-counter creature while "
            "preserving the instant/sorcery miracle core."
        ),
        "adds": ["Sun Titan"],
        "cuts": ["Hexing Squelcher"],
    },
    "artifact_etb_value": {
        "hypothesis": (
            "Artifact ETB cards from the Lorehold corpus may turn Mind Stone blink "
            "into mana/card velocity without cutting the miracle spell package."
        ),
        "adds": ["Archaeomancer's Map", "Soul-Guide Lantern", "The One Ring"],
        "cuts": ["Bender's Waterskin", "Victory Chimes", "Hexing Squelcher"],
    },
}


STRATEGIC_METRICS = (
    "lorehold_cost_paid",
    "lorehold_spell_cast",
    "spell_cast_mana_trigger",
    "birgi_spell_cast_mana",
    "ritual_mana_added",
    "miracle_cast",
    "tutor_resolved",
    "random_discard_after_tutor",
    "topdeck_manipulation_activated",
    "damage_prevention_shield_created",
    "discard_to_top_replacement",
    "lorehold_rummage_discard_to_top",
    "lorehold_spell_rummage_discard_to_top",
    "hand_to_topdeck_activation",
    "lorehold_spell_rummage",
    "squee_to_graveyard",
    "squee_upkeep_return",
    "squee_return_after_known_graveyard_entry",
)

MIRACLE_CORE_NAMES = {
    "Artist's Talent",
    "Molecule Man",
    "Pinnacle Monk // Mystic Peak",
    "Prismari Pianist",
    "Storm Herd",
    "The Scarlet Witch",
}
CUT_SAFETY_BLOCKED_STATUSES = {
    "locked_do_not_cut",
    "protected_until_same_lane_win",
    "protected_until_same_function_replacement_wins",
}
CUT_SAFETY_RISKY_STATUSES = {"risky_cut_only_same_lane"}
CUT_SAFETY_PROTECTED_STATUSES = CUT_SAFETY_BLOCKED_STATUSES | CUT_SAFETY_RISKY_STATUSES
PRIOR_PACKAGE_BLOCKED_DECISIONS = {
    "reject_or_rework",
    "invalid_or_incomplete",
    "forced_access_no_lift_reject_or_rework",
    "tie_watch_strategy_regression",
    "insufficient_card_outcome_sample",
}


def card_signature(cards: object) -> tuple[str, ...]:
    if not isinstance(cards, list):
        return ()
    return tuple(sorted(normalize_name(str(card)) for card in cards if str(card).strip()))


def package_signature_key(adds: object, cuts: object) -> str:
    return json.dumps(
        {"adds": card_signature(adds), "cuts": card_signature(cuts)},
        sort_keys=True,
    )


def load_package_definition_file(path: Path) -> dict[str, dict[str, Any]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    raw_packages = payload.get("packages") if isinstance(payload, dict) else None
    if not isinstance(raw_packages, list):
        raise ValueError(f"{path} must contain a packages list")
    definitions: dict[str, dict[str, Any]] = {}
    for index, row in enumerate(raw_packages):
        if not isinstance(row, dict):
            raise ValueError(f"{path} package #{index + 1} must be an object")
        package_key = str(row.get("package_key") or "").strip()
        if not package_key:
            raise ValueError(f"{path} package #{index + 1} is missing package_key")
        adds = row.get("adds")
        cuts = row.get("cuts")
        hypothesis = str(row.get("hypothesis") or "").strip()
        if not isinstance(adds, list) or not all(str(card).strip() for card in adds):
            raise ValueError(f"{path} package {package_key} must contain non-empty adds")
        if not isinstance(cuts, list) or not all(str(card).strip() for card in cuts):
            raise ValueError(f"{path} package {package_key} must contain non-empty cuts")
        if not hypothesis:
            raise ValueError(f"{path} package {package_key} is missing hypothesis")
        definitions[package_key] = {
            "family": row.get("family") or "external_manifest",
            "hypothesis": hypothesis,
            "adds": [str(card) for card in adds],
            "cuts": [str(card) for card in cuts],
        }
        for optional_key in (
            "allow_miracle_core_cuts",
            "cut_safety_override_reason",
            "registry_protected_cut_override_reason",
        ):
            if optional_key in row:
                definitions[package_key][optional_key] = row[optional_key]
    return definitions


def merge_package_definitions(package_files: list[Path]) -> tuple[dict[str, dict[str, Any]], list[str]]:
    definitions = dict(PACKAGE_DEFINITIONS)
    loaded_paths: list[str] = []
    for path in package_files:
        loaded = load_package_definition_file(path)
        collisions = sorted(set(definitions) & set(loaded))
        if collisions:
            raise ValueError(f"{path} redefines existing package(s): {', '.join(collisions)}")
        definitions.update(loaded)
        loaded_paths.append(str(path))
    return definitions, loaded_paths


def utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")


def connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def card_meta(conn: sqlite3.Connection, card_name: str) -> sqlite3.Row:
    row = conn.execute(
        "SELECT * FROM card_oracle_cache WHERE normalized_name=?",
        (normalize_name(card_name),),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"missing card_oracle_cache row for {card_name}")
    return row


def load_canonical_snapshot() -> dict[str, dict[str, Any]]:
    if not CANONICAL_SNAPSHOT.exists():
        return {}
    raw = json.loads(CANONICAL_SNAPSHOT.read_text(encoding="utf-8"))
    return {normalize_name(str(name)): value for name, value in raw.items() if isinstance(value, dict)}


CANONICAL_RULES = load_canonical_snapshot()


def load_cut_safety_manifest(path: Path | None) -> dict[str, Any]:
    if path is None:
        return {"enabled": False, "path": None, "summary": {}, "cuts_by_name": {}}
    if not path.exists():
        return {
            "enabled": True,
            "path": str(path),
            "missing": True,
            "summary": {},
            "cuts_by_name": {},
        }
    payload = json.loads(path.read_text(encoding="utf-8"))
    manifest = payload.get("cut_safety_manifest") if isinstance(payload, dict) else None
    if not isinstance(manifest, dict):
        manifest = payload if isinstance(payload, dict) else {}
    cuts_by_name = {
        str(row.get("card_name")): row
        for row in manifest.get("cuts", [])
        if isinstance(row, dict) and row.get("card_name")
    }
    return {
        "enabled": True,
        "path": str(path),
        "summary": manifest.get("summary") or {},
        "cuts_by_name": cuts_by_name,
    }


def load_registry_cut_guard(path: Path | None) -> dict[str, Any]:
    if path is None:
        return {"enabled": False, "path": None, "protected_names": []}
    if not path.exists():
        return {
            "enabled": True,
            "path": str(path),
            "missing": True,
            "protected_names": [],
        }
    payload = json.loads(path.read_text(encoding="utf-8"))
    protected_names = [
        str(name)
        for name in payload.get("protected_cards_until_same_function_replacement_wins", [])
        if str(name).strip()
    ]
    return {
        "enabled": True,
        "path": str(path),
        "protected_names": protected_names,
        "summary": {
            "protected_registry_cut_count": len(protected_names),
        },
    }


def merge_registry_cut_guard(
    cut_safety: dict[str, Any],
    registry_guard: dict[str, Any],
) -> dict[str, Any]:
    if not cut_safety.get("enabled") or not registry_guard.get("enabled"):
        return cut_safety
    if registry_guard.get("missing"):
        merged = dict(cut_safety)
        summary = dict(merged.get("summary") or {})
        summary["registry_guard_missing"] = True
        merged["summary"] = summary
        return merged

    merged = dict(cut_safety)
    cuts_by_name = dict(merged.get("cuts_by_name") or {})
    for card_name in registry_guard.get("protected_names") or []:
        cuts_by_name[card_name] = {
            **cuts_by_name.get(card_name, {}),
            "card_name": card_name,
            "status": "protected_until_same_function_replacement_wins",
            "current_decision": "registry_protected",
            "current_lane": cuts_by_name.get(card_name, {}).get("current_lane") or "registry_protected",
            "effective_role": cuts_by_name.get(card_name, {}).get("effective_role"),
            "reason": (
                "registry protects this card until a same-function replacement "
                "wins a current-leader gate"
            ),
        }
    summary = dict(merged.get("summary") or {})
    summary.update(registry_guard.get("summary") or {})
    merged["summary"] = summary
    merged["registry_guard"] = {
        "enabled": True,
        "path": registry_guard.get("path"),
        "missing": bool(registry_guard.get("missing")),
        "protected_names": list(registry_guard.get("protected_names") or []),
    }
    merged["cuts_by_name"] = cuts_by_name
    return merged


def classify_package_cut_safety(
    definition: dict[str, Any],
    cut_safety: dict[str, Any],
) -> dict[str, Any]:
    if not cut_safety.get("enabled"):
        return {"status": "not_checked", "reason": "cut-safety preflight disabled", "cuts": []}
    if cut_safety.get("missing"):
        return {
            "status": "not_checked",
            "reason": "cut-safety report missing",
            "cuts": [],
        }

    cuts_by_name = cut_safety.get("cuts_by_name") or {}
    cut_rows = [
        cuts_by_name[cut]
        for cut in definition.get("cuts", [])
        if cut in cuts_by_name
    ]
    if not cut_rows:
        return {
            "status": "clear",
            "reason": "no proposed cut has previous blocker evidence",
            "cuts": [],
        }

    override_reason = str(definition.get("cut_safety_override_reason") or "").strip()
    protected_rows = [
        row
        for row in cut_rows
        if row.get("status") in CUT_SAFETY_PROTECTED_STATUSES
    ]
    blocked_rows = [
        row
        for row in cut_rows
        if row.get("status") in CUT_SAFETY_BLOCKED_STATUSES
    ]
    registry_blocked_rows = [
        row
        for row in blocked_rows
        if row.get("status") == "protected_until_same_function_replacement_wins"
    ]
    risky_rows = [
        row
        for row in cut_rows
        if row.get("status") in CUT_SAFETY_RISKY_STATUSES
    ]
    cut_summaries = [
        {
            "card_name": row.get("card_name"),
            "status": row.get("status"),
            "current_lane": row.get("current_lane"),
            "effective_role": row.get("effective_role"),
            "worst_strong_seed_delta_pp": row.get("worst_strong_seed_delta_pp"),
            "best_delta_pp": row.get("best_delta_pp"),
            "reason": row.get("reason"),
        }
        for row in protected_rows
    ]

    registry_override_reason = str(
        definition.get("registry_protected_cut_override_reason") or ""
    ).strip()
    if registry_blocked_rows and not registry_override_reason:
        names = ", ".join(str(row.get("card_name")) for row in registry_blocked_rows)
        return {
            "status": "blocked_cut_safety",
            "reason": f"proposed cuts are registry-protected: {names}",
            "cuts": cut_summaries,
        }
    if protected_rows and not override_reason:
        names = ", ".join(str(row.get("card_name")) for row in protected_rows)
        return {
            "status": "blocked_cut_safety",
            "reason": f"proposed cuts already have blocker evidence: {names}",
            "cuts": cut_summaries,
        }
    if blocked_rows and override_reason:
        status = "override_locked_cut_safety"
    elif risky_rows and override_reason:
        status = "override_risky_cut_safety"
    elif registry_blocked_rows and registry_override_reason:
        status = "override_registry_cut_safety"
    else:
        status = "clear"
    return {
        "status": status,
        "reason": registry_override_reason or override_reason or "cut-safety preflight passed",
        "cuts": cut_summaries,
    }


def load_prior_package_results(paths: list[Path]) -> dict[str, Any]:
    def compact_side(side: dict[str, Any]) -> dict[str, Any]:
        telemetry = side.get("telemetry") or {}
        return {
            "wins": side.get("wins"),
            "losses": side.get("losses"),
            "stalls": side.get("stalls"),
            "win_rate": side.get("win_rate"),
            "avg_win_turn": side.get("avg_win_turn"),
            "strategic_event_counts": telemetry.get("strategic_event_counts") or {},
        }

    def side_from_record_string(raw: Any) -> dict[str, Any]:
        if not isinstance(raw, str):
            return {}
        match = re.match(r"^\s*(\d+)-(\d+)(?:-(\d+))?\s*$", raw)
        if not match:
            return {}
        wins = int(match.group(1))
        losses = int(match.group(2))
        stalls = int(match.group(3) or 0)
        games = max(1, wins + losses + stalls)
        return {
            "wins": wins,
            "losses": losses,
            "stalls": stalls,
            "win_rate": round(wins / games * 100, 2),
        }

    def side_from_observation(result: dict[str, Any], prefix: str) -> dict[str, Any]:
        side = side_from_record_string(result.get(prefix))
        wins_key = f"{prefix}_wins"
        losses_key = f"{prefix}_losses"
        if result.get(wins_key) is not None and result.get(losses_key) is not None:
            wins = int(result.get(wins_key) or 0)
            losses = int(result.get(losses_key) or 0)
            games = max(1, wins + losses)
            side.update(
                {
                    "wins": wins,
                    "losses": losses,
                    "stalls": side.get("stalls", 0),
                    "win_rate": round(wins / games * 100, 2),
                }
            )
        return side

    def gate_summary_from_flat_result(result: dict[str, Any]) -> dict[str, Any]:
        baseline = side_from_observation(result, "baseline")
        candidate = side_from_observation(result, "candidate")
        if not baseline and not candidate and result.get("delta_pp") is None:
            return {}
        return {
            "baseline": baseline,
            "candidate": candidate,
            "delta_pp": result.get("delta_pp"),
        }

    def package_rows_from_payload(payload: Any) -> list[dict[str, Any]]:
        if not isinstance(payload, dict):
            return []
        rows: list[dict[str, Any]] = []
        packages = payload.get("packages")
        if isinstance(packages, list):
            rows.extend(row for row in packages if isinstance(row, dict))
        for section_name in ("post_squee_package_gates", "safe_package_gates"):
            section = payload.get(section_name)
            section_rows = section.get("rows") if isinstance(section, dict) else None
            if isinstance(section_rows, list):
                for row in section_rows:
                    if isinstance(row, dict):
                        copied = dict(row)
                        copied.setdefault("source_section", section_name)
                        rows.append(copied)
        manifest = payload.get("cut_safety_manifest")
        cuts = manifest.get("cuts") if isinstance(manifest, dict) else None
        if isinstance(cuts, list):
            for cut in cuts:
                if not isinstance(cut, dict):
                    continue
                cut_card = str(cut.get("card_name") or "").strip()
                observations = cut.get("observations")
                if not isinstance(observations, list):
                    continue
                for observation in observations:
                    if not isinstance(observation, dict):
                        continue
                    row = dict(observation)
                    if cut_card and not row.get("cuts"):
                        row["cuts"] = [cut_card]
                    row.setdefault("source_section", "cut_safety_manifest")
                    if "gate_summary" not in row:
                        row["gate_summary"] = {
                            "baseline": side_from_observation(row, "baseline"),
                            "candidate": side_from_observation(row, "candidate"),
                            "delta_pp": row.get("delta_pp"),
                        }
                    rows.append(row)
        return rows

    by_package_key: dict[str, list[dict[str, Any]]] = {}
    by_signature: dict[str, list[dict[str, Any]]] = {}
    loaded_paths: list[str] = []
    missing_paths: list[str] = []
    for path in paths:
        if not path.exists():
            missing_paths.append(str(path))
            continue
        payload = json.loads(path.read_text(encoding="utf-8"))
        packages = package_rows_from_payload(payload)
        if not packages:
            continue
        loaded_paths.append(str(path))
        for result in packages:
            if not isinstance(result, dict) or not result.get("package_key"):
                continue
            if "gate_summary" not in result:
                flat_gate = gate_summary_from_flat_result(result)
                if flat_gate:
                    result = dict(result)
                    result["gate_summary"] = flat_gate
            gate = result.get("gate_summary") or {}
            aggregate = result.get("aggregate") or {}
            exposure = result.get("exposure_summary") or {}
            if not exposure and result.get("gate_json"):
                detailed_gate_path = Path(str(result.get("gate_json")))
                if detailed_gate_path.exists():
                    try:
                        detailed_gate = summarize_gate(
                            load_gate_result(detailed_gate_path),
                            f"synergy_{result.get('package_key')}",
                        )
                        exposure = package_exposure_summary(
                            detailed_gate,
                            adds=list(result.get("adds") or []),
                            cuts=list(result.get("cuts") or []),
                        )
                        if not gate:
                            gate = detailed_gate
                    except Exception:
                        exposure = {}
            raw_decision = str(result.get("decision") or aggregate.get("decision") or "")
            exposure_decision = gate_decision(
                gate,
                exposure,
                forced_access_mode=str(result.get("forced_access_mode") or "none"),
            )
            if exposure.get("low_candidate_added_card_use"):
                decision = exposure_decision
            else:
                decision = raw_decision or exposure_decision
            baseline = gate.get("baseline") or {}
            candidate = gate.get("candidate") or {}
            delta_pp = gate.get("delta_pp", aggregate.get("delta_pp_total", result.get("delta_pp")))
            has_gate_telemetry = bool(
                (baseline.get("telemetry") or candidate.get("telemetry"))
                if isinstance(baseline, dict) and isinstance(candidate, dict)
                else False
            )
            package_result = {
                "package_key": result.get("package_key"),
                "source_report": str(path),
                "source_section": result.get("source_section"),
                "family": result.get("family"),
                "adds": result.get("adds") or [],
                "cuts": result.get("cuts") or [],
                "adds_signature": card_signature(result.get("adds") or []),
                "cuts_signature": card_signature(result.get("cuts") or []),
                "decision": decision,
                "delta_pp": delta_pp,
                "baseline": compact_side(baseline),
                "candidate": compact_side(candidate),
                "strategic_delta": strategic_delta(gate) if gate and has_gate_telemetry else {},
                "exposure_summary": exposure,
                "gate_json": result.get("gate_json"),
                "gate_markdown": result.get("gate_markdown"),
                "gate_returncode": result.get("gate_returncode"),
                "forced_access_mode": result.get("forced_access_mode") or "none",
            }
            by_package_key.setdefault(str(result.get("package_key")), []).append(package_result)
            by_signature.setdefault(
                package_signature_key(package_result["adds"], package_result["cuts"]),
                [],
            ).append(package_result)
    return {
        "enabled": bool(paths),
        "loaded_paths": loaded_paths,
        "missing_paths": missing_paths,
        "by_package_key": by_package_key,
        "by_signature": by_signature,
        "summary": {
            "loaded_report_count": len(loaded_paths),
            "missing_report_count": len(missing_paths),
            "package_key_count": len(by_package_key),
            "signature_count": len(by_signature),
        },
    }


def parse_registry_swap_scope(scope: str) -> tuple[list[str], list[str]]:
    if ";" not in scope:
        return [], []
    add_part, cut_part = scope.split(";", 1)
    adds = [
        match.group(1).strip().strip(".,")
        for match in re.finditer(r"\+\s*(.*?)(?=\s*(?:/|,)\s*\+|;|$)", add_part)
        if match.group(1).strip().strip(".,")
    ]
    cuts = [
        match.group(1).strip().strip(".,")
        for match in re.finditer(r"-\s*(.*?)(?=\s*(?:/|,)\s*-|;|$)", cut_part)
        if match.group(1).strip().strip(".,")
    ]
    return adds, cuts


def load_registry_prior_results(path: Path | None) -> dict[str, Any]:
    if path is None:
        return {"enabled": False, "loaded_paths": [], "missing_paths": [], "results": []}
    if not path.exists():
        return {
            "enabled": True,
            "loaded_paths": [],
            "missing_paths": [str(path)],
            "results": [],
        }

    payload = json.loads(path.read_text(encoding="utf-8"))
    results: list[dict[str, Any]] = []
    for section in ("tested", "leader_follow_up_probes", "leader_watchlist_probes"):
        for index, row in enumerate(payload.get(section) or []):
            status = str(row.get("status") or "")
            if not status.startswith("rejected"):
                continue
            adds, cuts = parse_registry_swap_scope(str(row.get("swap_or_scope") or ""))
            if not adds or not cuts:
                continue
            for add in adds:
                package_result = {
                    "package_key": f"registry:{section}:{index}:{normalize_name(add)}",
                    "source_report": str(path),
                    "family": "registry_rejected",
                    "adds": [add],
                    "cuts": cuts,
                    "adds_signature": card_signature([add]),
                    "cuts_signature": card_signature(cuts),
                    "decision": "reject_or_rework",
                    "delta_pp": None,
                    "baseline": {},
                    "candidate": {},
                    "strategic_delta": {},
                    "gate_json": None,
                    "gate_markdown": None,
                    "gate_returncode": None,
                    "registry_section": section,
                    "registry_status": status,
                    "registry_result": row.get("result"),
                    "registry_learning": row.get("learning"),
                }
                results.append(package_result)
    return {
        "enabled": True,
        "loaded_paths": [str(path)],
        "missing_paths": [],
        "results": results,
        "summary": {
            "registry_prior_result_count": len(results),
        },
    }


def merge_registry_prior_results(
    prior_results: dict[str, Any],
    registry_results: dict[str, Any],
) -> dict[str, Any]:
    if not registry_results.get("enabled"):
        return prior_results
    merged = dict(prior_results)
    by_package_key = {
        key: list(value)
        for key, value in (merged.get("by_package_key") or {}).items()
    }
    by_signature = {
        key: list(value)
        for key, value in (merged.get("by_signature") or {}).items()
    }
    for row in registry_results.get("results") or []:
        by_package_key.setdefault(str(row.get("package_key")), []).append(row)
        by_signature.setdefault(package_signature_key(row.get("adds"), row.get("cuts")), []).append(row)
    summary = dict(merged.get("summary") or {})
    summary.update(registry_results.get("summary") or {})
    summary["package_key_count"] = len(by_package_key)
    summary["signature_count"] = len(by_signature)
    merged["by_package_key"] = by_package_key
    merged["by_signature"] = by_signature
    merged["summary"] = summary
    merged["loaded_paths"] = list(merged.get("loaded_paths") or []) + list(
        registry_results.get("loaded_paths") or []
    )
    merged["missing_paths"] = list(merged.get("missing_paths") or []) + list(
        registry_results.get("missing_paths") or []
    )
    return merged


def classify_package_prior_evidence(
    package_key: str,
    definition: dict[str, Any],
    prior_results: dict[str, Any],
    forced_access_mode: str = "none",
) -> dict[str, Any]:
    if not prior_results.get("enabled"):
        return {"status": "not_checked", "reason": "prior package evidence disabled", "matches": []}
    target_adds = tuple(
        sorted(normalize_name(str(card)) for card in definition.get("adds", []) if str(card).strip())
    )
    target_cuts = tuple(
        sorted(normalize_name(str(card)) for card in definition.get("cuts", []) if str(card).strip())
    )
    matches = (prior_results.get("by_package_key") or {}).get(package_key) or []
    signature_matches = (prior_results.get("by_signature") or {}).get(
        package_signature_key(definition.get("adds") or [], definition.get("cuts") or []),
        [],
    )
    if not matches and not signature_matches:
        return {
            "status": "clear",
            "reason": "no previous package-key or add/cut signature result",
            "matches": [],
        }

    exact_key_matches = [
        row
        for row in matches
        if tuple(row.get("adds_signature") or sorted(normalize_name(str(card)) for card in row.get("adds", [])))
        == target_adds
        and tuple(row.get("cuts_signature") or sorted(normalize_name(str(card)) for card in row.get("cuts", [])))
        == target_cuts
    ]
    exact_matches: list[dict[str, Any]] = []
    seen = set()
    for row in exact_key_matches + list(signature_matches):
        marker = (
            row.get("source_report"),
            row.get("package_key"),
            tuple(row.get("adds_signature") or ()),
            tuple(row.get("cuts_signature") or ()),
        )
        if marker in seen:
            continue
        seen.add(marker)
        exact_matches.append(row)
    if not exact_matches:
        return {
            "status": "same_key_different_signature",
            "reason": "previous package-key result has different add/cut signature",
            "matches": matches,
        }
    blocking = [
        row
        for row in exact_matches
        if row.get("decision") in PRIOR_PACKAGE_BLOCKED_DECISIONS
    ]
    override_reason = str(definition.get("prior_evidence_override_reason") or "").strip()
    if blocking and not override_reason:
        latest = blocking[-1]
        if forced_access_mode and forced_access_mode != "none":
            return {
                "status": "forced_access_diagnostic_despite_prior_reject",
                "reason": (
                    f"exact package already produced `{latest.get('decision')}`, "
                    "but forced-access mode is diagnostic and still needs natural confirmation"
                ),
                "matches": blocking,
            }
        return {
            "status": "blocked_prior_reject",
            "reason": f"exact package already produced `{latest.get('decision')}`",
            "matches": blocking,
        }
    if blocking and override_reason:
        return {
            "status": "override_prior_reject",
            "reason": override_reason,
            "matches": blocking,
        }
    return {
        "status": "seen_no_blocker",
        "reason": "previous exact package result was not a reject blocker",
        "matches": exact_matches,
    }


def role_category_for_effect(effect_data: dict[str, Any]) -> str:
    effect = str(effect_data.get("effect") or "")
    if effect in {"draw_cards", "draw_engine", "loot", "topdeck_manipulation"}:
        return "draw"
    if effect in {"ramp_engine", "ramp_permanent", "ramp_ritual", "static_cost_reduction"}:
        return "ramp"
    if effect in {"copy_spell", "graveyard_flashback_grant", "passive"}:
        return "engine"
    if effect in {"remove_permanent", "remove_creature", "damage"}:
        return "removal"
    if effect in {"token_maker", "extra_turn"}:
        return "wincon"
    return "synergy"


def battle_rule_runtime_priority(rule: dict[str, Any]) -> tuple[int, str]:
    try:
        effect_data = json.loads(str(rule.get("effect_json") or "{}"))
    except Exception:
        effect_data = {}
    scope = str(effect_data.get("battle_model_scope") or "")
    if scope == "lands_controlled_treasure_count_v1":
        return (0, str(rule.get("logical_rule_key") or ""))
    if scope == "single_treasure_creation_v1":
        return (50, str(rule.get("logical_rule_key") or ""))
    if rule.get("review_status") == "verified" and rule.get("execution_status") == "auto":
        return (10, str(rule.get("logical_rule_key") or ""))
    return (20, str(rule.get("logical_rule_key") or ""))


def active_rules_for_card(conn: sqlite3.Connection, card_name: str) -> list[dict[str, Any]]:
    table = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='battle_card_rules'"
    ).fetchone()
    if table:
        rows = conn.execute(
            """
            SELECT logical_rule_key, effect_json, deck_role_json, source,
                   confidence, review_status, execution_status, rule_version
            FROM battle_card_rules
            WHERE normalized_name=?
              AND review_status IN ('verified', 'active', 'needs_review')
              AND execution_status != 'disabled'
            ORDER BY logical_rule_key
            """,
            (normalize_name(card_name),),
        ).fetchall()
        if rows:
            rules = [dict(row) for row in rows]
            rules.sort(key=battle_rule_runtime_priority)
            return rules

    canonical = CANONICAL_RULES.get(normalize_name(card_name))
    if not canonical:
        return []
    review_status = str(canonical.get("battle_rule_review_status") or "")
    execution_status = str(canonical.get("battle_rule_execution_status") or "")
    if review_status not in {"verified", "active", "needs_review"} or execution_status == "disabled":
        return []
    effect_data = {
        key: value
        for key, value in canonical.items()
        if not key.startswith("battle_rule_")
    }
    return [
        {
            "logical_rule_key": canonical.get("battle_rule_logical_key")
            or f"canonical_snapshot:{normalize_name(card_name)}",
            "effect_json": json.dumps(effect_data, ensure_ascii=True, sort_keys=True),
            "deck_role_json": json.dumps(
                {
                    "category": role_category_for_effect(effect_data),
                    "effect": effect_data.get("effect") or "synergy",
                },
                ensure_ascii=True,
                sort_keys=True,
            ),
            "source": canonical.get("battle_rule_source") or "canonical_snapshot",
            "confidence": canonical.get("battle_rule_confidence") or 0.0,
            "review_status": review_status,
            "execution_status": execution_status,
            "rule_version": canonical.get("battle_rule_version") or 1,
        }
    ]


def tags_from_rules(rules: list[dict[str, Any]]) -> list[str]:
    tags: list[str] = ["synergy"]
    for rule in rules:
        try:
            role = json.loads(str(rule.get("deck_role_json") or "{}"))
        except Exception:
            role = {}
        category = str(role.get("category") or "").strip()
        if category and category not in tags:
            tags.append(category)
    return tags


def deck_cards(conn: sqlite3.Connection, deck_id: int) -> list[sqlite3.Row]:
    return conn.execute(
        "SELECT * FROM deck_cards WHERE deck_id=? ORDER BY is_commander DESC, card_name",
        (deck_id,),
    ).fetchall()


def upsert_reviewed_rules_for_cards(
    conn: sqlite3.Connection,
    card_names: list[str],
) -> dict[str, int]:
    wanted = {normalize_name(name) for name in card_names}
    if not wanted:
        return {}
    rows = [
        row
        for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH)
        if normalize_name(row["card_name"]) in wanted
    ]
    if not rows:
        return {}
    battle_rule_registry.ensure_battle_card_rules(conn)
    counts: dict[str, int] = {}
    for row in rows:
        battle_rule_registry.upsert_battle_card_rule(
            conn,
            row["card_name"],
            row["effect_json"],
            source=row["source"],
            confidence=row["confidence"],
            review_status=row["review_status"],
            execution_status=row.get("execution_status", "auto"),
            deck_role_json=row.get("deck_role_json"),
            notes=row.get("notes", ""),
            oracle_hash=row.get("oracle_hash"),
            logical_rule_key_value=row.get("logical_rule_key"),
        )
        counts[row["card_name"]] = counts.get(row["card_name"], 0) + 1
    conn.commit()
    return counts


def load_runtime_package_rule_rows(
    path: Path,
    card_names: list[str],
) -> list[dict[str, Any]]:
    wanted = {normalize_name(name) for name in card_names}
    if not wanted or not path.exists():
        return []
    payload = json.loads(path.read_text(encoding="utf-8"))
    proposals = payload.get("proposals") if isinstance(payload, dict) else None
    if not isinstance(proposals, list):
        return []

    rows: list[dict[str, Any]] = []
    for proposal in proposals:
        if not isinstance(proposal, dict):
            continue
        card_name = str(proposal.get("card_name") or "").strip()
        if not card_name or normalize_name(card_name) not in wanted:
            continue
        effect_json = proposal.get("effect_json")
        deck_role_json = proposal.get("deck_role_json")
        if not isinstance(effect_json, dict) or not effect_json:
            continue
        rows.append(
            {
                "card_name": card_name,
                "effect_json": effect_json,
                "deck_role_json": deck_role_json if isinstance(deck_role_json, dict) else None,
                "logical_rule_key": proposal.get("logical_rule_key"),
                "source": str(proposal.get("source") or "curated"),
                "confidence": float(proposal.get("confidence") or 1.0),
                "review_status": str(proposal.get("review_status") or "verified"),
                "execution_status": str(proposal.get("execution_status") or "auto"),
                "notes": str(proposal.get("notes") or "").strip(),
                "oracle_hash": proposal.get("oracle_hash"),
                "shadow_handling": proposal.get("shadow_handling"),
            }
        )
    return rows


def runtime_package_proposal_paths(
    proposals_path: Path | Iterable[Path] | None = None,
) -> list[Path]:
    if proposals_path is None:
        return [path for path in DEFAULT_RUNTIME_PACKAGE_PROPOSAL_REPORTS]
    if isinstance(proposals_path, (str, Path)):
        return [Path(proposals_path)]
    return [Path(path) for path in proposals_path]


def upsert_runtime_package_rules_for_cards(
    conn: sqlite3.Connection,
    card_names: list[str],
    *,
    proposals_path: Path | Iterable[Path] | None = None,
) -> dict[str, dict[str, int]]:
    rows: list[dict[str, Any]] = []
    for path in runtime_package_proposal_paths(proposals_path):
        rows.extend(load_runtime_package_rule_rows(path, card_names))
    if not rows:
        return {}
    battle_rule_registry.ensure_battle_card_rules(conn)
    counts: dict[str, dict[str, int]] = {}
    for row in rows:
        card_name = row["card_name"]
        logical_key = str(row.get("logical_rule_key") or "")
        upserted = battle_rule_registry.upsert_battle_card_rule(
            conn,
            card_name,
            row["effect_json"],
            source=row["source"],
            confidence=row["confidence"],
            review_status=row["review_status"],
            execution_status=row["execution_status"],
            deck_role_json=row.get("deck_role_json"),
            notes=row.get("notes", ""),
            oracle_hash=row.get("oracle_hash"),
            logical_rule_key_value=logical_key or None,
        )
        summary = counts.setdefault(card_name, {"upserted": 0, "shadow_deprecated": 0})
        if upserted:
            summary["upserted"] += 1
        if row.get("shadow_handling") == "deprecate_nonmatching_rows" and logical_key:
            before = conn.total_changes
            conn.execute(
                """
                UPDATE battle_card_rules
                SET review_status='deprecated',
                    execution_status='disabled',
                    updated_at=?,
                    last_seen_at=COALESCE(last_seen_at, ?)
                WHERE normalized_name=?
                  AND logical_rule_key<>?
                  AND execution_status!='disabled'
                """,
                (
                    battle_rule_registry.utc_now(),
                    battle_rule_registry.utc_now(),
                    normalize_name(card_name),
                    logical_key,
                ),
            )
            summary["shadow_deprecated"] += max(0, conn.total_changes - before)
    conn.commit()
    return counts


def is_miracle_core_cut(row: sqlite3.Row) -> bool:
    name = str(row["card_name"] or "")
    type_line = str(row["type_line"] or "")
    oracle_text = str(row["oracle_text"] or "").lower()
    tag = str(row["functional_tag"] or "").lower()
    cmc = float(row["cmc"] or 0)
    if name in MIRACLE_CORE_NAMES:
        return True
    if ("Instant" in type_line or "Sorcery" in type_line) and cmc >= 4:
        return True
    if ("Instant" in type_line or "Sorcery" in type_line) and tag in {"wincon", "board_wipe", "draw"}:
        return True
    if "instant or sorcery" in oracle_text:
        return True
    if "noncreature spell" in oracle_text and tag in {"draw", "wincon", "engine", "creature"}:
        return True
    return False


def apply_package(
    conn: sqlite3.Connection,
    *,
    deck_id: int,
    adds: list[str],
    cuts: list[str],
    allow_miracle_core_cuts: bool = False,
    runtime_package_proposals_path: Path | Iterable[Path] | None = None,
) -> dict[str, Any]:
    if len(adds) != len(cuts):
        raise RuntimeError("package adds and cuts must have the same length")

    rows = deck_cards(conn, deck_id)
    current = {normalize_name(str(row["card_name"])): row for row in rows}
    add_keys = {normalize_name(name) for name in adds}
    cut_keys = {normalize_name(name) for name in cuts}

    missing_cuts = [name for name in cuts if normalize_name(name) not in current]
    duplicate_adds = [name for name in adds if normalize_name(name) in current]
    commander_cuts = [
        name for name in cuts if current.get(normalize_name(name)) and current[normalize_name(name)]["is_commander"]
    ]
    miracle_core_cuts = [
        name
        for name in cuts
        if current.get(normalize_name(name)) and is_miracle_core_cut(current[normalize_name(name)])
    ]
    if missing_cuts:
        raise RuntimeError(f"missing cuts in source deck: {', '.join(missing_cuts)}")
    if duplicate_adds:
        raise RuntimeError(f"added cards already in source deck: {', '.join(duplicate_adds)}")
    if commander_cuts:
        raise RuntimeError(f"cannot cut commander cards: {', '.join(commander_cuts)}")
    if miracle_core_cuts and not allow_miracle_core_cuts:
        raise RuntimeError(
            "cannot cut Lorehold miracle/core spell payoff without explicit override: "
            + ", ".join(miracle_core_cuts)
        )

    reviewed_rule_upserts = upsert_reviewed_rules_for_cards(conn, adds)
    runtime_package_rule_upserts = upsert_runtime_package_rules_for_cards(
        conn,
        adds,
        proposals_path=runtime_package_proposals_path,
    )
    columns = [row[1] for row in conn.execute("PRAGMA table_info(deck_cards)") if row[1] != "id"]
    candidate_rows: list[dict[str, Any]] = []
    for row in rows:
        if normalize_name(str(row["card_name"])) in cut_keys:
            continue
        candidate_rows.append({column: row[column] for column in columns})

    for card_name in adds:
        meta = card_meta(conn, card_name)
        rules = active_rules_for_card(conn, card_name)
        tags = tags_from_rules(rules)
        entry = {column: None for column in columns}
        entry.update(
            {
                "deck_id": deck_id,
                "card_id": None,
                "card_name": card_name,
                "quantity": 1,
                "functional_tag": tags[1] if len(tags) > 1 else "synergy",
                "tag_confidence": None,
                "is_commander": 0,
                "is_partner": 0,
                "cmc": meta["cmc"],
                "type_line": meta["type_line"],
                "oracle_text": meta["oracle_text"],
            }
        )
        if "functional_tags_json" in entry:
            entry["functional_tags_json"] = json.dumps(tags, ensure_ascii=True)
        if "semantic_tags_v2_json" in entry:
            entry["semantic_tags_v2_json"] = "[]"
        if "battle_rules_json" in entry:
            entry["battle_rules_json"] = json.dumps(rules, ensure_ascii=True, sort_keys=True)
        candidate_rows.append(entry)

    conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (deck_id,))
    placeholders = ",".join("?" for _ in columns)
    for row in candidate_rows:
        conn.execute(
            f"INSERT INTO deck_cards ({','.join(columns)}) VALUES ({placeholders})",
            [row.get(column) for column in columns],
        )
    conn.commit()

    return {
        "deck_id": deck_id,
        "adds": adds,
        "cuts": cuts,
        "allow_miracle_core_cuts": allow_miracle_core_cuts,
        "miracle_core_cuts": miracle_core_cuts,
        "row_count": len(candidate_rows),
        "total_cards": sum(int(row.get("quantity") or 1) for row in candidate_rows),
        "reviewed_rule_upserts": reviewed_rule_upserts,
        "runtime_package_rule_upserts": runtime_package_rule_upserts,
        "added_rule_counts": {
            name: len(active_rules_for_card(conn, name))
            for name in adds
        },
    }


def run_gate(
    *,
    source_db: Path,
    candidate_db: Path,
    package_key: str,
    baseline_deck_id: int = 607,
    focus_cards: list[str] | None = None,
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    simulation_seed: int,
    game_timeout_seconds: float,
    deck_process_timeout_seconds: float = 0.0,
    gate_timeout_seconds: float = 0.0,
    stem: str = "lorehold_synergy_package_gate",
    no_game_checkpoint: bool = False,
    forced_access_mode: str = "none",
) -> subprocess.CompletedProcess[str]:
    cmd = [
        sys.executable,
        str(SCRIPT_DIR / "lorehold_variant_battle_gate.py"),
        "--db",
        str(source_db),
        "--deck-ids",
        str(baseline_deck_id),
        "--candidate-db",
        str(candidate_db),
        "--candidate-key",
        f"synergy_{package_key}",
        "--candidate-name",
        f"Lorehold synergy package: {package_key}",
        "--candidate-archetype",
        "synergy-package",
        "--candidate-deck-id",
        str(baseline_deck_id),
        "--games",
        str(games),
        "--opponent-limit",
        str(opponent_limit),
        "--opponent-seed",
        str(opponent_seed),
        "--simulation-seed",
        str(simulation_seed),
        "--game-timeout-seconds",
        str(game_timeout_seconds),
        "--deck-process-timeout-seconds",
        str(deck_process_timeout_seconds),
        "--isolate-deck-process",
        "--stem",
        stem,
    ]
    if forced_access_mode and forced_access_mode != "none":
        cmd.extend(["--force-focus-access", forced_access_mode])
    if no_game_checkpoint:
        cmd.append("--no-game-checkpoint")
    env = dict(os.environ)
    env["PYTHONHASHSEED"] = "0"
    if focus_cards:
        env["MANALOOM_FOCUS_ACCESS_CARDS"] = json.dumps(
            sorted({str(card).strip() for card in focus_cards if str(card).strip()}),
            ensure_ascii=False,
        )
    timeout = float(gate_timeout_seconds or 0.0)
    if timeout <= 0:
        total_games = max(1, games) * max(1, opponent_limit)
        per_deck_timeout = float(deck_process_timeout_seconds or 0.0)
        if per_deck_timeout <= 0:
            per_deck_timeout = max(
                120.0,
                total_games * max(5.0, float(game_timeout_seconds or 0.0)) + 120.0,
            )
        timeout = max(60.0, (per_deck_timeout * 2.0) + 60.0)

    process = subprocess.Popen(
        cmd,
        cwd=str(SCRIPT_DIR),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env,
        start_new_session=True,
    )
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        return subprocess.CompletedProcess(cmd, process.returncode, stdout, stderr)
    except subprocess.TimeoutExpired as exc:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except Exception:
            process.terminate()
        try:
            stdout, stderr = process.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except Exception:
                process.kill()
            stdout, stderr = process.communicate()
        timeout_message = f"\npackage gate subprocess timed out after {timeout:.1f}s"
        return subprocess.CompletedProcess(
            cmd,
            124,
            (exc.stdout or "") + (stdout or ""),
            (exc.stderr or "") + (stderr or "") + timeout_message,
        )


def load_gate_result(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def compact_game_results(game_results: list[dict[str, Any]]) -> list[dict[str, Any]]:
    compacted: list[dict[str, Any]] = []
    for row in game_results:
        if not isinstance(row, dict):
            continue
        compacted.append(
            {
                "game_id": row.get("game_id"),
                "game_index": row.get("game_index"),
                "opponent": row.get("opponent"),
                "opponent_archetype": row.get("opponent_archetype"),
                "result": row.get("result"),
                "turns": row.get("turns"),
                "reason": row.get("reason"),
            }
        )
    return compacted


def compact_gate_telemetry(telemetry: dict[str, Any]) -> dict[str, Any]:
    return {
        "strategic_event_counts": telemetry.get("strategic_event_counts") or {},
        "strategic_games": telemetry.get("strategic_games") or {},
        "event_counts": telemetry.get("event_counts") or {},
        "card_event_counts": telemetry.get("card_event_counts") or {},
        "card_event_counts_by_game": telemetry.get("card_event_counts_by_game") or {},
        "card_strategy_counts": telemetry.get("card_strategy_counts") or {},
        "focus_card_trace_card_counts_by_game": (
            telemetry.get("focus_card_trace_card_counts_by_game") or {}
        ),
        "focus_card_access_summary": compact_focus_card_access_summary(telemetry),
        "focus_card_access_by_game": compact_focus_card_access_by_game(telemetry),
        "top_cards": telemetry.get("top_cards") or [],
        "lorehold_attack_restrictions": telemetry.get("lorehold_attack_restrictions") or {},
        "lorehold_attack_restriction_source_events": (
            telemetry.get("lorehold_attack_restriction_source_events") or {}
        ),
    }


def compact_gate_row(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "status": row.get("status"),
        "error": row.get("error"),
        "games": row.get("games"),
        "wins": row.get("wins"),
        "losses": row.get("losses"),
        "stalls": row.get("stalls"),
        "win_rate": row.get("win_rate"),
        "avg_win_turn": row.get("avg_win_turn"),
        "game_results": compact_game_results(row.get("game_results") or []),
        "telemetry": compact_gate_telemetry(row.get("telemetry") or {}),
    }


def summarize_gate(report: dict[str, Any], candidate_key: str, baseline_deck_id: int = 607) -> dict[str, Any]:
    rows = report.get("results") or []
    summary: dict[str, Any] = {}
    baseline_key = f"deck_{baseline_deck_id}"
    for row in rows:
        key = str(row.get("deck_key") or "")
        if key == baseline_key:
            summary["baseline"] = compact_gate_row(row)
        elif key == candidate_key:
            summary["candidate"] = compact_gate_row(row)
    baseline_wr = float((summary.get("baseline") or {}).get("win_rate") or 0.0)
    candidate_wr = float((summary.get("candidate") or {}).get("win_rate") or 0.0)
    summary["delta_pp"] = round(candidate_wr - baseline_wr, 2)
    return summary


def strategic_counts(row: dict[str, Any]) -> dict[str, int]:
    telemetry = row.get("telemetry") or {}
    strategic_counts = telemetry.get("strategic_event_counts") or {}
    event_counts = telemetry.get("event_counts") or {}
    return {
        metric: int(strategic_counts.get(metric) or event_counts.get(metric) or 0)
        for metric in STRATEGIC_METRICS
    }


def strategic_delta(gate: dict[str, Any]) -> dict[str, int]:
    baseline = strategic_counts(gate.get("baseline") or {})
    candidate = strategic_counts(gate.get("candidate") or {})
    return {
        metric: int(candidate.get(metric, 0) - baseline.get(metric, 0))
        for metric in STRATEGIC_METRICS
    }


def strategic_delta_text(gate: dict[str, Any]) -> str:
    delta = strategic_delta(gate)
    if not delta:
        return "-"
    labels = {
        "lorehold_cost_paid": "cost",
        "lorehold_spell_cast": "spell",
        "spell_cast_mana_trigger": "spell mana",
        "birgi_spell_cast_mana": "birgi mana",
        "ritual_mana_added": "ritual",
        "miracle_cast": "miracle",
        "tutor_resolved": "tutor",
        "random_discard_after_tutor": "random discard",
        "topdeck_manipulation_activated": "topdeck",
        "damage_prevention_shield_created": "shield",
        "discard_to_top_replacement": "discard-to-top",
        "lorehold_rummage_discard_to_top": "rummage-to-top",
        "lorehold_spell_rummage_discard_to_top": "spell-rummage-to-top",
        "hand_to_topdeck_activation": "hand to top",
        "lorehold_spell_rummage": "spell rummage",
        "squee_to_graveyard": "squee gy",
        "squee_upkeep_return": "squee return",
        "squee_return_after_known_graveyard_entry": "squee explained",
    }
    return ", ".join(f"{labels[key]} {value:+d}" for key, value in delta.items())


def card_event_breakdown(telemetry: dict[str, Any], card_name: str) -> dict[str, int]:
    def breakdown_from_counts(counts: Any) -> dict[str, int]:
        breakdown: dict[str, int] = {}
        if isinstance(counts, dict):
            for key, value in counts.items():
                prefix, separator, name = str(key).partition(":")
                if not separator or name != card_name:
                    continue
                breakdown[prefix] = breakdown.get(prefix, 0) + int(value or 0)
        return dict(sorted(breakdown.items()))

    breakdown = breakdown_from_counts(telemetry.get("card_event_counts") or {})
    if breakdown:
        return breakdown
    return breakdown_from_counts(telemetry.get("card_strategy_counts") or {})


def card_event_breakdown_by_game(telemetry: dict[str, Any], card_name: str) -> dict[str, dict[str, int]]:
    by_game = telemetry.get("card_event_counts_by_game") or {}
    if not isinstance(by_game, dict):
        return {}
    result: dict[str, dict[str, int]] = {}
    for raw_game_id, counts in by_game.items():
        breakdown: dict[str, int] = {}
        if not isinstance(counts, dict):
            continue
        for key, value in counts.items():
            prefix, separator, name = str(key).partition(":")
            if not separator or name != card_name:
                continue
            breakdown[prefix] = breakdown.get(prefix, 0) + int(value or 0)
        if breakdown:
            result[str(raw_game_id)] = dict(sorted(breakdown.items()))
    return result


def result_record(game_results: list[dict[str, Any]]) -> dict[str, Any]:
    wins = losses = stalls = 0
    for row in game_results:
        result = str(row.get("result") or "")
        if result == "win":
            wins += 1
        elif result == "loss":
            losses += 1
        else:
            stalls += 1
    games = wins + losses + stalls
    return {
        "games": games,
        "wins": wins,
        "losses": losses,
        "stalls": stalls,
        "win_rate": round(wins / max(1, games) * 100, 2) if games else 0.0,
    }


def card_exposure_outcome_summary(row: dict[str, Any], card_name: str) -> dict[str, Any]:
    telemetry = row.get("telemetry") or {}
    game_results = [
        game
        for game in row.get("game_results") or []
        if isinstance(game, dict) and game.get("game_id")
    ]
    use_by_game = card_event_breakdown_by_game(telemetry, card_name)
    access_by_game = focus_card_access_game_profiles(telemetry, card_name)
    annotated_games: list[dict[str, Any]] = []
    for game in game_results:
        game_id = str(game.get("game_id") or "")
        event_breakdown = use_by_game.get(game_id) or {}
        recorded_use_count = sum(int(value or 0) for value in event_breakdown.values())
        access_profile = access_by_game.get(game_id) or {}
        if recorded_use_count > 0:
            exposure_status = "used"
        elif bool(access_profile.get("accessed")):
            exposure_status = "accessed_not_used"
        elif bool(access_profile.get("near_access")):
            exposure_status = "near_access_not_used"
        elif bool(access_profile.get("library_only")):
            exposure_status = "library_only_not_used"
        elif access_profile:
            exposure_status = "observed_not_used"
        else:
            exposure_status = "not_observed"
        annotated_games.append(
            {
                "game_id": game_id,
                "opponent": game.get("opponent"),
                "result": game.get("result"),
                "turns": game.get("turns"),
                "recorded_use_count": recorded_use_count,
                "event_breakdown": event_breakdown,
                "access_status": exposure_status,
                "accessed": recorded_use_count > 0 or bool(access_profile.get("accessed")),
                "near_access": bool(access_profile.get("near_access")),
                "dominant_zone": access_profile.get("dominant_zone"),
            }
        )

    used_games = [game for game in annotated_games if game["access_status"] == "used"]
    accessed_or_used_games = [
        game for game in annotated_games if game["access_status"] in {"used", "accessed_not_used"}
    ]
    near_or_better_games = [
        game
        for game in annotated_games
        if game["access_status"] in {"used", "accessed_not_used", "near_access_not_used"}
    ]
    status_counts: dict[str, int] = {}
    for game in annotated_games:
        status = str(game.get("access_status") or "not_observed")
        status_counts[status] = status_counts.get(status, 0) + 1
    return {
        "card_name": card_name,
        "all_games": result_record(annotated_games),
        "used_games": result_record(used_games),
        "accessed_or_used_games": result_record(accessed_or_used_games),
        "near_access_or_better_games": result_record(near_or_better_games),
        "status_counts": dict(sorted(status_counts.items())),
        "sample_quality": (
            "card_used_sample"
            if used_games
            else "card_accessed_not_used_sample"
            if accessed_or_used_games
            else "card_near_access_only_sample"
            if near_or_better_games
            else "no_card_exposure_sample"
        ),
        "games": annotated_games[:20],
        "games_truncated": len(annotated_games) > 20,
    }


def focus_location_trace_count(telemetry: dict[str, Any], card_name: str) -> tuple[int, int]:
    by_game = telemetry.get("focus_card_trace_card_counts_by_game") or {}
    if not isinstance(by_game, dict):
        return 0, 0
    total = 0
    games = 0
    for counts in by_game.values():
        if not isinstance(counts, dict):
            continue
        count = int(counts.get(card_name) or 0)
        total += count
        if count > 0:
            games += 1
    return total, games


ACCESS_ZONES = {"hand", "battlefield", "graveyard", "exile", "stack"}


def card_names_from_snapshots(value: Any) -> set[str]:
    names: set[str] = set()
    if not isinstance(value, list):
        return names
    for item in value:
        if isinstance(item, Mapping):
            name = str(item.get("name") or "").strip()
        else:
            name = str(item or "").strip()
        if name:
            names.add(name)
    return names


def focus_card_access_profile(telemetry: dict[str, Any], card_name: str) -> dict[str, Any]:
    """Summarize whether a focused card was actually accessible, not merely present."""

    compact_summary = telemetry.get("focus_card_access_summary") or {}
    if isinstance(compact_summary, dict) and isinstance(compact_summary.get(card_name), dict):
        return dict(compact_summary[card_name])

    traces_by_game = telemetry.get("focus_card_game_traces") or {}
    trace_count, trace_games = focus_location_trace_count(telemetry, card_name)
    profile: dict[str, Any] = {
        "trace_count": trace_count,
        "trace_games": trace_games,
        "zone_counts": {},
        "accessed_trace_count": 0,
        "accessed_games": 0,
        "near_access_trace_count": 0,
        "near_access_games": 0,
        "drawn_trace_count": 0,
        "drawn_games": 0,
        "opening_hand_trace_count": 0,
        "opening_hand_games": 0,
        "library_only_games": 0,
        "dominant_zone": None,
    }
    if not isinstance(traces_by_game, dict):
        return profile

    zone_counts: dict[str, int] = {}
    accessed_games: set[str] = set()
    near_access_games: set[str] = set()
    drawn_games: set[str] = set()
    opening_games: set[str] = set()
    library_only_games: set[str] = set()
    observed_games: set[str] = set()
    detailed_trace_count = 0

    for raw_game_id, traces in traces_by_game.items():
        game_id = str(raw_game_id)
        if not isinstance(traces, list):
            continue
        game_observed = False
        game_accessed = False
        game_near = False
        game_library_only = False
        for trace in traces:
            if not isinstance(trace, Mapping):
                continue
            data = trace.get("data") or {}
            if not isinstance(data, Mapping):
                continue
            zones = data.get("focus_card_zones") or {}
            zone_info = zones.get(card_name) if isinstance(zones, Mapping) else None
            zone = ""
            if isinstance(zone_info, Mapping):
                zone = str(zone_info.get("zone") or "").strip()
            if not zone:
                continue
            detailed_trace_count += 1
            zone_counts[zone] = zone_counts.get(zone, 0) + 1
            if zone != "absent":
                game_observed = True
            if zone == "library":
                game_library_only = True
            drawn_names = (
                card_names_from_snapshots(data.get("drawn_for_turn"))
                | card_names_from_snapshots(data.get("drawn"))
                | card_names_from_snapshots(data.get("first_draw"))
            )
            if card_name in drawn_names:
                profile["drawn_trace_count"] = int(profile["drawn_trace_count"]) + 1
                drawn_games.add(game_id)
                game_accessed = True
            if card_name in set(data.get("hand_focus") or []):
                game_accessed = True
            if zone in ACCESS_ZONES:
                profile["accessed_trace_count"] = int(profile["accessed_trace_count"]) + 1
                game_accessed = True
            if (
                isinstance(zone_info, Mapping)
                and bool(zone_info.get("library_top_7"))
            ) or card_name in set(data.get("library_top_focus") or []):
                profile["near_access_trace_count"] = int(profile["near_access_trace_count"]) + 1
                game_near = True
            if data.get("phase") == "opening_keep" and zone == "hand":
                profile["opening_hand_trace_count"] = int(profile["opening_hand_trace_count"]) + 1
                opening_games.add(game_id)
                game_accessed = True
        if game_observed:
            observed_games.add(game_id)
        if game_accessed:
            accessed_games.add(game_id)
        elif game_near:
            near_access_games.add(game_id)
        elif game_library_only:
            library_only_games.add(game_id)

    if detailed_trace_count:
        profile["trace_count"] = detailed_trace_count
        profile["trace_games"] = len(observed_games)
    profile["zone_counts"] = dict(sorted(zone_counts.items()))
    profile["accessed_games"] = len(accessed_games)
    profile["near_access_games"] = len(near_access_games)
    profile["drawn_games"] = len(drawn_games)
    profile["opening_hand_games"] = len(opening_games)
    profile["library_only_games"] = len(library_only_games)
    if zone_counts:
        profile["dominant_zone"] = max(zone_counts.items(), key=lambda item: item[1])[0]
    return profile


def focus_card_access_game_profiles(telemetry: dict[str, Any], card_name: str) -> dict[str, dict[str, Any]]:
    compact_by_game = telemetry.get("focus_card_access_by_game") or {}
    if isinstance(compact_by_game, dict) and isinstance(compact_by_game.get(card_name), dict):
        return {
            str(game_id): dict(profile)
            for game_id, profile in compact_by_game[card_name].items()
            if isinstance(profile, Mapping)
        }

    traces_by_game = telemetry.get("focus_card_game_traces") or {}
    if not isinstance(traces_by_game, dict):
        return {}

    profiles: dict[str, dict[str, Any]] = {}
    for raw_game_id, traces in traces_by_game.items():
        game_id = str(raw_game_id)
        if not isinstance(traces, list):
            continue
        profile: dict[str, Any] = {
            "trace_count": 0,
            "zone_counts": {},
            "accessed": False,
            "near_access": False,
            "drawn": False,
            "opening_hand": False,
            "library_only": False,
            "dominant_zone": None,
        }
        zone_counts: dict[str, int] = {}
        observed = False
        saw_library = False
        for trace in traces:
            if not isinstance(trace, Mapping):
                continue
            data = trace.get("data") or {}
            if not isinstance(data, Mapping):
                continue
            zones = data.get("focus_card_zones") or {}
            zone_info = zones.get(card_name) if isinstance(zones, Mapping) else None
            zone = ""
            if isinstance(zone_info, Mapping):
                zone = str(zone_info.get("zone") or "").strip()
            if not zone:
                continue
            profile["trace_count"] = int(profile["trace_count"]) + 1
            zone_counts[zone] = zone_counts.get(zone, 0) + 1
            if zone != "absent":
                observed = True
            if zone == "library":
                saw_library = True
            drawn_names = (
                card_names_from_snapshots(data.get("drawn_for_turn"))
                | card_names_from_snapshots(data.get("drawn"))
                | card_names_from_snapshots(data.get("first_draw"))
            )
            if card_name in drawn_names:
                profile["drawn"] = True
                profile["accessed"] = True
            if card_name in set(data.get("hand_focus") or []):
                profile["accessed"] = True
            if zone in ACCESS_ZONES:
                profile["accessed"] = True
            if (
                isinstance(zone_info, Mapping)
                and bool(zone_info.get("library_top_7"))
            ) or card_name in set(data.get("library_top_focus") or []):
                profile["near_access"] = True
            if data.get("phase") == "opening_keep" and zone == "hand":
                profile["opening_hand"] = True
                profile["accessed"] = True

        if not observed and not int(profile["trace_count"]):
            continue
        profile["zone_counts"] = dict(sorted(zone_counts.items()))
        if zone_counts:
            profile["dominant_zone"] = max(zone_counts.items(), key=lambda item: item[1])[0]
        profile["library_only"] = bool(
            saw_library and not profile["accessed"] and not profile["near_access"]
        )
        profiles[game_id] = profile
    return profiles


def compact_focus_card_access_summary(telemetry: dict[str, Any]) -> dict[str, dict[str, Any]]:
    existing = telemetry.get("focus_card_access_summary") or {}
    if isinstance(existing, dict) and existing:
        return existing
    traces_by_game = telemetry.get("focus_card_game_traces") or {}
    if not isinstance(traces_by_game, dict):
        return {}
    card_names: set[str] = set()
    for traces in traces_by_game.values():
        if not isinstance(traces, list):
            continue
        for trace in traces:
            if not isinstance(trace, Mapping):
                continue
            data = trace.get("data") or {}
            if not isinstance(data, Mapping):
                continue
            zones = data.get("focus_card_zones") or {}
            if isinstance(zones, Mapping):
                card_names.update(str(name) for name in zones.keys())
    return {
        card_name: focus_card_access_profile(telemetry, card_name)
        for card_name in sorted(card_names)
    }


def compact_focus_card_access_by_game(telemetry: dict[str, Any]) -> dict[str, dict[str, dict[str, Any]]]:
    existing = telemetry.get("focus_card_access_by_game") or {}
    if isinstance(existing, dict) and existing:
        return existing
    traces_by_game = telemetry.get("focus_card_game_traces") or {}
    if not isinstance(traces_by_game, dict):
        return {}
    card_names: set[str] = set()
    for traces in traces_by_game.values():
        if not isinstance(traces, list):
            continue
        for trace in traces:
            if not isinstance(trace, Mapping):
                continue
            data = trace.get("data") or {}
            if not isinstance(data, Mapping):
                continue
            zones = data.get("focus_card_zones") or {}
            if isinstance(zones, Mapping):
                card_names.update(str(name) for name in zones.keys())
    return {
        card_name: focus_card_access_game_profiles(telemetry, card_name)
        for card_name in sorted(card_names)
    }


def access_status(recorded_use_count: int, profile: dict[str, Any]) -> str:
    if recorded_use_count > 0:
        return "used"
    if int(profile.get("accessed_games") or 0) > 0:
        return "accessed_not_used"
    if int(profile.get("near_access_games") or 0) > 0:
        return "near_access_not_used"
    if int(profile.get("library_only_games") or 0) > 0:
        return "library_only_not_used"
    if int(profile.get("trace_games") or 0) > 0:
        return "observed_not_used"
    return "not_observed"


def side_card_exposure(row: dict[str, Any], cards: list[str]) -> dict[str, Any]:
    telemetry = row.get("telemetry") or {}
    summaries: list[dict[str, Any]] = []
    for card_name in cards:
        event_breakdown = card_event_breakdown(telemetry, card_name)
        recorded_use_count = sum(event_breakdown.values())
        access_profile = focus_card_access_profile(telemetry, card_name)
        location_trace_count = int(access_profile.get("trace_count") or 0)
        location_trace_games = int(access_profile.get("trace_games") or 0)
        status = access_status(recorded_use_count, access_profile)
        summaries.append(
            {
                "card_name": card_name,
                "recorded_use_count": recorded_use_count,
                "event_breakdown": event_breakdown,
                "location_trace_count": location_trace_count,
                "location_trace_games": location_trace_games,
                "access_profile": access_profile,
                "outcome_summary": card_exposure_outcome_summary(row, card_name),
                "status": status,
            }
        )
    cards_with_access = sum(
        1
        for item in summaries
        if int(item.get("recorded_use_count") or 0) > 0
        or int((item.get("access_profile") or {}).get("accessed_games") or 0) > 0
    )
    cards_with_near_access = sum(
        1
        for item in summaries
        if int(item.get("recorded_use_count") or 0) > 0
        or int((item.get("access_profile") or {}).get("accessed_games") or 0) > 0
        or int((item.get("access_profile") or {}).get("near_access_games") or 0) > 0
    )
    return {
        "cards": summaries,
        "card_count": len(cards),
        "cards_with_recorded_use": sum(
            1 for item in summaries if int(item.get("recorded_use_count") or 0) > 0
        ),
        "cards_with_access": cards_with_access,
        "cards_with_near_access": cards_with_near_access,
        "total_recorded_use_count": sum(
            int(item.get("recorded_use_count") or 0) for item in summaries
        ),
        "all_cards_used": all(
            int(item.get("recorded_use_count") or 0) > 0 for item in summaries
        )
        if summaries
        else True,
        "all_cards_accessed": cards_with_access == len(summaries) if summaries else True,
        "all_cards_near_access": cards_with_near_access == len(summaries) if summaries else True,
    }


def package_exposure_status(candidate_added: dict[str, Any]) -> str:
    if candidate_added.get("all_cards_used", True):
        return "candidate_added_cards_used"
    if candidate_added.get("all_cards_accessed", False):
        return "candidate_added_cards_accessed_not_used"
    if candidate_added.get("all_cards_near_access", False):
        return "candidate_added_cards_near_access_low_use"
    return "candidate_added_card_low_access"


def package_exposure_next_step(candidate_added: dict[str, Any]) -> str:
    if candidate_added.get("all_cards_used", True):
        return "evaluate_winrate_and_strategy_delta"
    if candidate_added.get("all_cards_accessed", False):
        return "inspect_play_heuristic_or_runtime_for_accessed_card"
    if candidate_added.get("all_cards_near_access", False):
        return "rerun_targeted_access_or_draw_window"
    return "increase_sample_or_run_forced_access_gate"


def package_exposure_summary(
    gate: dict[str, Any],
    *,
    adds: list[str],
    cuts: list[str],
) -> dict[str, Any]:
    candidate = gate.get("candidate") or {}
    baseline = gate.get("baseline") or {}
    candidate_added = side_card_exposure(candidate, adds)
    baseline_cut = side_card_exposure(baseline, cuts)
    return {
        "candidate_added_cards": candidate_added,
        "baseline_cut_cards": baseline_cut,
        "low_candidate_added_card_use": not bool(candidate_added.get("all_cards_used", True)),
        "low_candidate_added_card_access": not bool(candidate_added.get("all_cards_accessed", True)),
        "status": package_exposure_status(candidate_added),
        "next_step": package_exposure_next_step(candidate_added),
    }


def exposure_summary_text(exposure: dict[str, Any]) -> str:
    candidate = exposure.get("candidate_added_cards") or {}
    cards = candidate.get("cards") or []
    if not cards:
        return "-"
    parts = []
    for item in cards:
        profile = item.get("access_profile") or {}
        outcome = item.get("outcome_summary") or {}
        used_games = outcome.get("used_games") or {}
        parts.append(
            (
                f"{item.get('card_name')} use={int(item.get('recorded_use_count') or 0)}"
                f" access_games={int(profile.get('accessed_games') or 0)}"
                f" near_games={int(profile.get('near_access_games') or 0)}"
                f" dominant_zone={profile.get('dominant_zone') or '-'}"
                f" used_record={int(used_games.get('wins') or 0)}W/"
                f"{int(used_games.get('losses') or 0)}L/"
                f"{int(used_games.get('stalls') or 0)}S"
            )
        )
    status = exposure.get("status") or "unknown"
    return f"{status}: " + ", ".join(parts)


LOW_EXPOSURE_STATUSES = {
    "candidate_added_card_low_access",
    "candidate_added_card_low_exposure",
    "candidate_added_cards_accessed_not_used",
    "candidate_added_cards_near_access_low_use",
}
MIN_CARD_OUTCOME_USED_GAMES = 2


def exposure_requires_inconclusive(exposure: dict[str, Any] | None) -> bool:
    if not exposure:
        return False
    if bool(exposure.get("low_candidate_added_card_use")):
        return True
    status = str(exposure.get("status") or "")
    if status in LOW_EXPOSURE_STATUSES:
        return True
    candidate_added = exposure.get("candidate_added_cards") or {}
    if "all_cards_used" in candidate_added:
        return not bool(candidate_added.get("all_cards_used"))
    return False


def card_outcome_used_game_count(card: dict[str, Any]) -> int | None:
    outcome = card.get("outcome_summary") or {}
    if not isinstance(outcome, dict):
        return None
    used = outcome.get("used_games") or {}
    if not isinstance(used, dict) or "games" not in used:
        return None
    return int(used.get("games") or 0)


def card_outcome_sample_decision(
    exposure: dict[str, Any] | None,
    forced_access_mode: str = "none",
    *,
    minimum_used_games: int = MIN_CARD_OUTCOME_USED_GAMES,
) -> str | None:
    if not exposure:
        return None
    under_minimum: list[dict[str, Any]] = []
    for group_key in ("candidate_added_cards", "baseline_cut_cards"):
        group = exposure.get(group_key) or {}
        cards = group.get("cards") or []
        if not isinstance(cards, list):
            continue
        for card in cards:
            if not isinstance(card, dict):
                continue
            used_games = card_outcome_used_game_count(card)
            if used_games is None:
                continue
            if used_games < minimum_used_games:
                under_minimum.append(
                    {
                        "group": group_key,
                        "card_name": card.get("card_name"),
                        "used_games": used_games,
                    }
                )
    if not under_minimum:
        return None
    if forced_access_mode and forced_access_mode != "none":
        return "forced_access_insufficient_card_outcome_sample"
    return "insufficient_card_outcome_sample"


def exposure_inconclusive_decision(
    exposure: dict[str, Any] | None,
    forced_access_mode: str = "none",
) -> str | None:
    if not exposure_requires_inconclusive(exposure):
        return card_outcome_sample_decision(exposure, forced_access_mode)
    if forced_access_mode and forced_access_mode != "none":
        return "forced_access_inconclusive_low_exposure"
    return "inconclusive_low_exposure"


def telemetry_present(side: dict[str, Any]) -> bool:
    return isinstance(side.get("telemetry"), Mapping)


def result_exposure_summary(result: dict[str, Any]) -> dict[str, Any]:
    exposure = result.get("exposure_summary") or {}
    if exposure:
        return exposure
    gate = result.get("gate_summary") or {}
    baseline = gate.get("baseline") or {}
    candidate = gate.get("candidate") or {}
    if not (
        isinstance(baseline, dict)
        and isinstance(candidate, dict)
        and (telemetry_present(baseline) or telemetry_present(candidate))
    ):
        return {}
    adds = list(result.get("adds") or [])
    cuts = list(result.get("cuts") or [])
    if not adds:
        return {}
    return package_exposure_summary(gate, adds=adds, cuts=cuts)


def gate_decision(
    gate: dict[str, Any],
    exposure: dict[str, Any] | None = None,
    forced_access_mode: str = "none",
) -> str:
    baseline = gate.get("baseline") or {}
    candidate = gate.get("candidate") or {}
    if not baseline or not candidate:
        return "invalid_or_incomplete"
    exposure_decision = exposure_inconclusive_decision(exposure, forced_access_mode)
    if exposure_decision:
        return exposure_decision

    baseline_wins = int(baseline.get("wins") or 0)
    baseline_losses = int(baseline.get("losses") or 0)
    candidate_wins = int(candidate.get("wins") or 0)
    candidate_losses = int(candidate.get("losses") or 0)
    delta = float(gate.get("delta_pp") or 0.0)
    strategic = strategic_delta(gate)

    if forced_access_mode and forced_access_mode != "none":
        if delta > 0 or candidate_wins > baseline_wins or (
            candidate_wins == baseline_wins and candidate_losses < baseline_losses
        ):
            return "forced_access_signal_requires_natural_confirmation"
        if delta == 0 and candidate_wins == baseline_wins:
            return "forced_access_tie_requires_natural_confirmation"
        return "forced_access_no_lift_reject_or_rework"

    if delta > 0:
        return "promote_to_deeper_gate"
    if candidate_wins > baseline_wins or (
        candidate_wins == baseline_wins and candidate_losses < baseline_losses
    ):
        return "promote_to_deeper_gate"
    if delta == 0 and candidate_wins == baseline_wins:
        if strategic.get("miracle_cast", 0) >= 0 and strategic.get("lorehold_spell_cast", 0) >= 0:
            return "tie_promote_to_deeper_gate"
        return "tie_watch_strategy_regression"
    return "reject_or_rework"


def package_result_decision(result: dict[str, Any], payload: dict[str, Any] | None = None) -> str:
    forced_access_mode = str(
        result.get("forced_access_mode")
        or (payload or {}).get("forced_access_mode")
        or "none"
    )
    exposure_decision = exposure_inconclusive_decision(
        result_exposure_summary(result),
        forced_access_mode,
    )
    if exposure_decision:
        return exposure_decision
    if result.get("decision"):
        return str(result["decision"])
    return gate_decision(
        result.get("gate_summary") or {},
        result_exposure_summary(result),
        forced_access_mode=forced_access_mode,
    )


def package_decision_counts(
    results: Iterable[dict[str, Any]],
    payload: dict[str, Any] | None = None,
) -> dict[str, int]:
    counts: dict[str, int] = {}
    for result in results:
        decision = package_result_decision(result, payload)
        counts[decision] = counts.get(decision, 0) + 1
    return dict(sorted(counts.items()))


def forced_access_confirmation_queue(payload: dict[str, Any]) -> list[dict[str, Any]]:
    queue: list[dict[str, Any]] = []
    for result in payload.get("packages") or []:
        decision = package_result_decision(result, payload)
        if decision not in {
            "forced_access_signal_requires_natural_confirmation",
            "forced_access_tie_requires_natural_confirmation",
        }:
            continue
        package_key = str(result.get("package_key") or "")
        if not package_key:
            continue
        suggested_command = (
            "python3 docs/hermes-analysis/manaloom-knowledge/scripts/"
            f"lorehold_synergy_package_gate.py --packages {package_key} "
            f"--games {max(1, int(payload.get('games_per_opponent') or 1))} "
            f"--opponent-limit {max(1, int(payload.get('opponent_limit') or 1))} "
            f"--opponent-seed {int(payload.get('opponent_seed') or 20260626)} "
            f"--simulation-seed {int(payload.get('simulation_seed') or 42)} "
            "--forced-access-mode none --ignore-prior-results"
        )
        queue.append(
            {
                "package_key": package_key,
                "family": result.get("family") or "misc",
                "adds": list(result.get("adds") or []),
                "cuts": list(result.get("cuts") or []),
                "forced_access_mode": result.get("forced_access_mode")
                or payload.get("forced_access_mode")
                or "none",
                "decision": decision,
                "natural_confirmation_status": "required",
                "next_step": "run_natural_gate_without_forced_access_before_promoting",
                "suggested_command": suggested_command,
            }
        )
    return queue


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Synergy Package Gate",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- source_db: `{payload['source_db']}`",
        f"- source_db_mutated: `false`",
        f"- games_per_opponent: `{payload['games_per_opponent']}`",
        f"- opponent_limit: `{payload['opponent_limit']}`",
        f"- opponent_seed: `{payload['opponent_seed']}`",
        f"- simulation_seed: `{payload['simulation_seed']}`",
        f"- preflight_only: `{payload.get('preflight_only')}`",
        f"- apply_only: `{payload.get('apply_only')}`",
        f"- no_game_checkpoint: `{payload.get('no_game_checkpoint')}`",
        f"- forced_access_mode: `{payload.get('forced_access_mode', 'none')}`",
        f"- runtime_package_proposal_reports: `{', '.join(payload.get('runtime_package_proposal_reports') or []) or '-'}`",
        f"- package_definition_files: `{', '.join(payload.get('package_definition_files') or []) or '-'}`",
        f"- cut_safety_report: `{payload.get('cut_safety_report') or '-'}`",
        f"- protected_cut_registry: `{payload.get('protected_cut_registry') or '-'}`",
        f"- prior_package_reports: `{', '.join(payload.get('prior_package_reports') or []) or '-'}`",
        f"- package_status_counts: `{json.dumps(payload.get('package_status_counts') or {}, sort_keys=True)}`",
        f"- package_decision_counts: `{json.dumps(payload.get('package_decision_counts') or {}, sort_keys=True)}`",
        "",
        "| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Exposure | Decision |",
        "| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- |",
    ]
    for result in payload["packages"]:
        preflight = (result.get("cut_safety") or {}).get("status") or "not_checked"
        if result.get("prior_evidence", {}).get("status") not in {None, "clear", "not_checked"}:
            preflight = f"{preflight};{result['prior_evidence']['status']}"
        if result.get("status") in {
            "skipped_cut_safety",
            "skipped_prior_evidence",
            "skipped_candidate_apply_error",
            "preflight_ready",
            "apply_ready",
        }:
            lines.append(
                "| {key} | {family} | {adds} | {cuts} | `{preflight}` | - | - | +0.00 | - | - | {status} |".format(
                    key=result["package_key"],
                    family=result.get("family") or "-",
                    adds=", ".join(result["adds"]),
                    cuts=", ".join(result["cuts"]),
                    preflight=preflight,
                    status=result.get("status"),
                )
            )
            continue
        gate = result.get("gate_summary") or {}
        baseline = gate.get("baseline") or {}
        candidate = gate.get("candidate") or {}
        delta = float(gate.get("delta_pp") or 0.0)
        exposure = result.get("exposure_summary") or {}
        decision = package_result_decision(result, payload)
        lines.append(
            "| {key} | {family} | {adds} | {cuts} | `{preflight}` | {bw}/{bl}/{bs} `{bwr:.2f}%` | "
            "{cw}/{cl}/{cs} `{cwr:.2f}%` | {delta:+.2f} | {strategic} | {exposure} | {decision} |".format(
                key=result["package_key"],
                family=result.get("family") or "-",
                adds=", ".join(result["adds"]),
                cuts=", ".join(result["cuts"]),
                preflight=preflight,
                bw=baseline.get("wins", 0),
                bl=baseline.get("losses", 0),
                bs=baseline.get("stalls", 0),
                bwr=float(baseline.get("win_rate") or 0.0),
                cw=candidate.get("wins", 0),
                cl=candidate.get("losses", 0),
                cs=candidate.get("stalls", 0),
                cwr=float(candidate.get("win_rate") or 0.0),
                delta=delta,
                strategic=strategic_delta_text(gate),
                exposure=exposure_summary_text(exposure),
                decision=decision,
            )
        )
    confirmation_queue = payload.get("forced_access_confirmation_queue") or []
    if confirmation_queue:
        lines.extend(
            [
                "",
                "## Forced Access Confirmation Queue",
                "",
                "| Package | Adds | Cuts | Forced Mode | Decision | Next Step |",
                "| --- | --- | --- | --- | --- | --- |",
            ]
        )
        for row in confirmation_queue:
            lines.append(
                "| {package} | {adds} | {cuts} | `{mode}` | `{decision}` | `{next_step}` |".format(
                    package=row.get("package_key"),
                    adds=", ".join(row.get("adds") or []),
                    cuts=", ".join(row.get("cuts") or []),
                    mode=row.get("forced_access_mode") or "none",
                    decision=row.get("decision"),
                    next_step=row.get("next_step"),
                )
            )
        lines.extend(["", "### Suggested Commands", ""])
        for row in confirmation_queue:
            lines.append(f"- `{row.get('suggested_command')}`")
    lines.extend(["", "## Package Notes", ""])
    for result in payload["packages"]:
        lines.extend(
            [
                f"### {result['package_key']}",
                "",
                f"- family: {result.get('family') or '-'}",
                f"- hypothesis: {result['hypothesis']}",
                f"- status: `{result.get('status') or 'gated'}`",
                f"- forced_access_mode: `{result.get('forced_access_mode') or payload.get('forced_access_mode', 'none')}`",
                f"- cut_safety: `{json.dumps(result.get('cut_safety') or {}, sort_keys=True)}`",
                f"- prior_evidence: `{json.dumps(result.get('prior_evidence') or {}, sort_keys=True)}`",
                f"- allow_miracle_core_cuts: `{result.get('candidate_meta', {}).get('allow_miracle_core_cuts')}`",
                f"- miracle_core_cuts: `{', '.join(result.get('candidate_meta', {}).get('miracle_core_cuts') or []) or '-'}`",
                f"- added_rule_counts: `{json.dumps(result.get('candidate_meta', {}).get('added_rule_counts') or {}, sort_keys=True)}`",
                f"- exposure_summary: `{json.dumps(result.get('exposure_summary') or {}, sort_keys=True)}`",
                f"- candidate_db: `{result.get('candidate_db') or '-'}`",
                f"- gate_markdown: `{result.get('gate_markdown') or '-'}`",
                f"- gate_json: `{result.get('gate_json') or '-'}`",
                f"- gate_returncode: `{result.get('gate_returncode')}`",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SOURCE_DB)
    parser.add_argument("--packages", default=",".join(PACKAGE_DEFINITIONS))
    parser.add_argument("--games", type=int, default=1)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--baseline-deck-id", type=int, default=607)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument("--game-timeout-seconds", type=float, default=90.0)
    parser.add_argument("--deck-process-timeout-seconds", type=float, default=0.0)
    parser.add_argument("--gate-timeout-seconds", type=float, default=0.0)
    parser.add_argument("--stem", default="lorehold_synergy_package_gate")
    parser.add_argument("--stamp", default=None)
    parser.add_argument(
        "--package-file",
        type=Path,
        action="append",
        default=[],
        help=(
            "External JSON package manifest with a packages list. "
            "Each row needs package_key, hypothesis, adds, and cuts."
        ),
    )
    parser.add_argument("--cut-safety-report", type=Path, default=DEFAULT_CUT_SAFETY_REPORT)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--no-cut-safety", action="store_true")
    parser.add_argument("--preflight-only", action="store_true")
    parser.add_argument("--apply-only", action="store_true")
    parser.add_argument("--no-game-checkpoint", action="store_true")
    parser.add_argument(
        "--forced-access-mode",
        choices=("none", "opening_hand", "library_top"),
        default="none",
        help=(
            "Run the variant gate in a test-only forced exposure mode for added "
            "focus cards. Use none for natural games."
        ),
    )
    parser.add_argument("--prior-package-report", type=Path, action="append")
    parser.add_argument("--ignore-prior-results", action="store_true")
    parser.add_argument(
        "--runtime-package-proposals",
        type=Path,
        action="append",
        help=(
            "Runtime proposal report to overlay into the copied candidate DB. "
            "May be passed multiple times; defaults include current local package reports."
        ),
    )
    args = parser.parse_args()

    source_db = args.source_db.resolve()
    stamp = args.stamp or utc_stamp()
    package_files = [path.resolve() for path in args.package_file]
    package_definitions, loaded_package_files = merge_package_definitions(package_files)
    cut_safety_report = None if args.no_cut_safety else args.cut_safety_report.resolve()
    cut_safety = load_cut_safety_manifest(cut_safety_report)
    registry_path = None if args.no_cut_safety else args.registry.resolve()
    registry_guard = load_registry_cut_guard(registry_path)
    cut_safety = merge_registry_cut_guard(cut_safety, registry_guard)
    prior_package_reports = [] if args.ignore_prior_results else [
        path.resolve() for path in (args.prior_package_report or list(DEFAULT_PRIOR_PACKAGE_REPORTS))
    ]
    runtime_package_proposal_reports = [
        path.resolve()
        for path in (
            args.runtime_package_proposals
            if args.runtime_package_proposals
            else list(DEFAULT_RUNTIME_PACKAGE_PROPOSAL_REPORTS)
        )
    ]
    prior_results = load_prior_package_results(prior_package_reports)
    registry_prior_results = load_registry_prior_results(registry_path)
    prior_results = merge_registry_prior_results(prior_results, registry_prior_results)
    package_keys = [key.strip() for key in args.packages.split(",") if key.strip()]
    unknown = [key for key in package_keys if key not in package_definitions]
    if unknown:
        raise SystemExit(f"unknown package(s): {', '.join(unknown)}")

    results: list[dict[str, Any]] = []
    for package_key in package_keys:
        definition = package_definitions[package_key]
        package_cut_safety = classify_package_cut_safety(definition, cut_safety)
        package_prior_evidence = classify_package_prior_evidence(
            package_key,
            definition,
            prior_results,
            forced_access_mode=args.forced_access_mode,
        )
        if package_cut_safety["status"] == "blocked_cut_safety":
            result = {
                "package_key": package_key,
                "family": definition.get("family") or "misc",
                "hypothesis": definition["hypothesis"],
                "adds": definition["adds"],
                "cuts": definition["cuts"],
                "status": "skipped_cut_safety",
                "decision": "not_run_cut_safety_blocked",
                "cut_safety": package_cut_safety,
                "prior_evidence": package_prior_evidence,
                "candidate_db": None,
                "candidate_meta": {},
                "gate_json": None,
                "gate_markdown": None,
                "gate_returncode": None,
                "gate_stdout_tail": "",
                "gate_stderr_tail": "",
                "gate_summary": {},
            }
            results.append(result)
            print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
            continue
        if package_prior_evidence["status"] == "blocked_prior_reject":
            result = {
                "package_key": package_key,
                "family": definition.get("family") or "misc",
                "hypothesis": definition["hypothesis"],
                "adds": definition["adds"],
                "cuts": definition["cuts"],
                "status": "skipped_prior_evidence",
                "decision": "not_run_prior_reject_blocked",
                "cut_safety": package_cut_safety,
                "prior_evidence": package_prior_evidence,
                "candidate_db": None,
                "candidate_meta": {},
                "gate_json": None,
                "gate_markdown": None,
                "gate_returncode": None,
                "gate_stdout_tail": "",
                "gate_stderr_tail": "",
                "gate_summary": {},
            }
            results.append(result)
            print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
            continue
        if args.preflight_only:
            result = {
                "package_key": package_key,
                "family": definition.get("family") or "misc",
                "hypothesis": definition["hypothesis"],
                "adds": definition["adds"],
                "cuts": definition["cuts"],
                "status": "preflight_ready",
                "decision": "preflight_ready_no_battle_evidence",
                "cut_safety": package_cut_safety,
                "prior_evidence": package_prior_evidence,
                "candidate_db": None,
                "candidate_meta": {},
                "gate_json": None,
                "gate_markdown": None,
                "gate_returncode": None,
                "gate_stdout_tail": "",
                "gate_stderr_tail": "",
                "gate_summary": {},
            }
            results.append(result)
            print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
            continue
        out_dir = REPORT_DIR / f"{args.stem}_{stamp}_{package_key}"
        out_dir.mkdir(parents=True, exist_ok=True)
        candidate_db = out_dir / "knowledge_candidate.db"
        try:
            shutil.copy2(source_db, candidate_db)
            with connect(candidate_db) as conn:
                candidate_meta = apply_package(
                    conn,
                    deck_id=args.baseline_deck_id,
                    adds=list(definition["adds"]),
                    cuts=list(definition["cuts"]),
                    allow_miracle_core_cuts=bool(definition.get("allow_miracle_core_cuts")),
                    runtime_package_proposals_path=runtime_package_proposal_reports,
                )
        except Exception as exc:
            result = {
                "package_key": package_key,
                "family": definition.get("family") or "misc",
                "hypothesis": definition["hypothesis"],
                "adds": definition["adds"],
                "cuts": definition["cuts"],
                "status": "skipped_candidate_apply_error",
                "decision": "invalid_or_incomplete",
                "cut_safety": package_cut_safety,
                "prior_evidence": package_prior_evidence,
                "candidate_db": str(candidate_db) if candidate_db.exists() else None,
                "candidate_meta": {},
                "gate_json": None,
                "gate_markdown": None,
                "gate_returncode": None,
                "gate_stdout_tail": "",
                "gate_stderr_tail": str(exc),
                "gate_summary": {},
            }
            results.append(result)
            print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
            continue

        if args.apply_only:
            result = {
                "package_key": package_key,
                "family": definition.get("family") or "misc",
                "hypothesis": definition["hypothesis"],
                "adds": definition["adds"],
                "cuts": definition["cuts"],
                "status": "apply_ready",
                "decision": "apply_ready_no_battle_evidence",
                "cut_safety": package_cut_safety,
                "prior_evidence": package_prior_evidence,
                "candidate_db": str(candidate_db),
                "candidate_meta": candidate_meta,
                "forced_access_mode": args.forced_access_mode,
                "gate_json": None,
                "gate_markdown": None,
                "gate_returncode": None,
                "gate_stdout_tail": "",
                "gate_stderr_tail": "",
                "gate_summary": {},
            }
            results.append(result)
            print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
            continue

        gate_stem = f"{args.stem}_{stamp}_{package_key}"
        completed = run_gate(
            source_db=source_db,
            candidate_db=candidate_db,
            package_key=package_key,
            baseline_deck_id=args.baseline_deck_id,
            focus_cards=list(definition["adds"]) + list(definition["cuts"]),
            games=max(1, args.games),
            opponent_limit=max(1, args.opponent_limit),
            opponent_seed=args.opponent_seed,
            simulation_seed=args.simulation_seed,
            game_timeout_seconds=max(0.0, args.game_timeout_seconds),
            deck_process_timeout_seconds=max(0.0, args.deck_process_timeout_seconds),
            gate_timeout_seconds=max(0.0, args.gate_timeout_seconds),
            stem=gate_stem,
            no_game_checkpoint=bool(args.no_game_checkpoint),
            forced_access_mode=args.forced_access_mode,
        )
        gate_json = REPORT_DIR / f"{gate_stem}.json"
        gate_md = REPORT_DIR / f"{gate_stem}.md"
        gate_summary: dict[str, Any] = {}
        if gate_json.exists():
            gate_summary = summarize_gate(
                load_gate_result(gate_json),
                f"synergy_{package_key}",
                baseline_deck_id=args.baseline_deck_id,
            )
        exposure_summary = (
            package_exposure_summary(
                gate_summary,
                adds=list(definition["adds"]),
                cuts=list(definition["cuts"]),
            )
            if gate_summary
            else {}
        )
        decision = (
            gate_decision(
                gate_summary,
                exposure_summary,
                forced_access_mode=args.forced_access_mode,
            )
            if gate_summary
            else "invalid_or_incomplete"
        )
        result = {
            "package_key": package_key,
            "family": definition.get("family") or "misc",
            "hypothesis": definition["hypothesis"],
            "adds": definition["adds"],
            "cuts": definition["cuts"],
            "status": "gated",
            "decision": decision,
            "cut_safety": package_cut_safety,
            "prior_evidence": package_prior_evidence,
            "candidate_db": str(candidate_db),
            "candidate_meta": candidate_meta,
            "forced_access_mode": args.forced_access_mode,
            "gate_json": str(gate_json) if gate_json.exists() else None,
            "gate_markdown": str(gate_md) if gate_md.exists() else None,
            "gate_returncode": completed.returncode,
            "gate_stdout_tail": completed.stdout[-2000:],
            "gate_stderr_tail": completed.stderr[-2000:],
            "gate_summary": gate_summary,
            "exposure_summary": exposure_summary,
        }
        results.append(result)
        print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)

    status_counts: dict[str, int] = {}
    for row in results:
        status_key = str(row.get("status") or "unknown")
        status_counts[status_key] = status_counts.get(status_key, 0) + 1
    decision_counts = package_decision_counts(
        results,
        {"forced_access_mode": args.forced_access_mode},
    )

    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_db": str(source_db),
        "source_db_mutated": False,
        "games_per_opponent": max(1, args.games),
        "opponent_limit": max(1, args.opponent_limit),
        "opponent_seed": args.opponent_seed,
        "simulation_seed": args.simulation_seed,
        "preflight_only": bool(args.preflight_only),
        "apply_only": bool(args.apply_only),
        "no_game_checkpoint": bool(args.no_game_checkpoint),
        "forced_access_mode": args.forced_access_mode,
        "runtime_package_proposal_reports": [str(path) for path in runtime_package_proposal_reports],
        "package_definition_files": loaded_package_files,
        "cut_safety_report": str(cut_safety_report) if cut_safety_report else None,
        "protected_cut_registry": str(registry_path) if registry_path else None,
        "protected_cut_registry_summary": registry_guard.get("summary") or {},
        "registry_prior_summary": registry_prior_results.get("summary") or {},
        "cut_safety_summary": cut_safety.get("summary") or {},
        "prior_package_reports": [str(path) for path in prior_package_reports],
        "prior_package_summary": prior_results.get("summary") or {},
        "package_status_counts": dict(sorted(status_counts.items())),
        "package_decision_counts": decision_counts,
        "packages": results,
    }
    payload["forced_access_confirmation_queue"] = forced_access_confirmation_queue(payload)
    report_json = REPORT_DIR / f"{args.stem}_{stamp}.json"
    report_md = REPORT_DIR / f"{args.stem}_{stamp}.md"
    report_json.write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    report_md.write_text(render_markdown(payload), encoding="utf-8")
    status = "ready"
    if args.preflight_only:
        status = "preflight_ready" if any(row.get("status") == "preflight_ready" for row in results) else "preflight_blocked"
    elif args.apply_only:
        status = "apply_ready" if any(row.get("status") == "apply_ready" for row in results) else "preflight_blocked"
    elif results and all(str(row.get("status", "")).startswith("skipped_") for row in results):
        status = "preflight_blocked"
    print(json.dumps({"status": status, "json": str(report_json), "markdown": str(report_md)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
