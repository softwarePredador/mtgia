#!/usr/bin/env python3
"""Build and gate small Lorehold synergy packages against the current shell.

The package runner is intentionally isolated: it copies a source SQLite DB,
applies card swaps to the copied deck 6, and delegates the actual comparison to
``lorehold_variant_battle_gate.py``. No source DB or PostgreSQL state is
mutated.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sqlite3
import subprocess
import sys
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
DEFAULT_SOURCE_DB = (
    REPORT_DIR
    / "lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob"
    / "knowledge_candidate.db"
)
DEFAULT_CUT_SAFETY_REPORT = REPORT_DIR / "lorehold_strategy_learning_audit_20260627_v1.json"
DEFAULT_PRIOR_PACKAGE_REPORTS = (
    REPORT_DIR / "lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json",
    REPORT_DIR / "lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json",
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
CUT_SAFETY_BLOCKED_STATUSES = {"locked_do_not_cut", "protected_until_same_lane_win"}
CUT_SAFETY_RISKY_STATUSES = {"risky_cut_only_same_lane"}
CUT_SAFETY_PROTECTED_STATUSES = CUT_SAFETY_BLOCKED_STATUSES | CUT_SAFETY_RISKY_STATUSES
PRIOR_PACKAGE_BLOCKED_DECISIONS = {"reject_or_rework", "invalid_or_incomplete"}


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
    else:
        status = "clear"
    return {
        "status": status,
        "reason": override_reason or "cut-safety preflight passed",
        "cuts": cut_summaries,
    }


def load_prior_package_results(paths: list[Path]) -> dict[str, Any]:
    def card_signature(cards: object) -> tuple[str, ...]:
        if not isinstance(cards, list):
            return ()
        return tuple(sorted(normalize_name(str(card)) for card in cards if str(card).strip()))

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

    by_package_key: dict[str, list[dict[str, Any]]] = {}
    loaded_paths: list[str] = []
    missing_paths: list[str] = []
    for path in paths:
        if not path.exists():
            missing_paths.append(str(path))
            continue
        payload = json.loads(path.read_text(encoding="utf-8"))
        packages = payload.get("packages") if isinstance(payload, dict) else None
        if not isinstance(packages, list):
            continue
        loaded_paths.append(str(path))
        for result in packages:
            if not isinstance(result, dict) or not result.get("package_key"):
                continue
            gate = result.get("gate_summary") or {}
            decision = str(result.get("decision") or gate_decision(gate))
            baseline = gate.get("baseline") or {}
            candidate = gate.get("candidate") or {}
            package_result = {
                "package_key": result.get("package_key"),
                "source_report": str(path),
                "family": result.get("family"),
                "adds": result.get("adds") or [],
                "cuts": result.get("cuts") or [],
                "adds_signature": card_signature(result.get("adds") or []),
                "cuts_signature": card_signature(result.get("cuts") or []),
                "decision": decision,
                "delta_pp": gate.get("delta_pp"),
                "baseline": compact_side(baseline),
                "candidate": compact_side(candidate),
                "strategic_delta": strategic_delta(gate) if gate else {},
                "gate_json": result.get("gate_json"),
                "gate_markdown": result.get("gate_markdown"),
                "gate_returncode": result.get("gate_returncode"),
            }
            by_package_key.setdefault(str(result.get("package_key")), []).append(package_result)
    return {
        "enabled": bool(paths),
        "loaded_paths": loaded_paths,
        "missing_paths": missing_paths,
        "by_package_key": by_package_key,
        "summary": {
            "loaded_report_count": len(loaded_paths),
            "missing_report_count": len(missing_paths),
            "package_key_count": len(by_package_key),
        },
    }


def classify_package_prior_evidence(
    package_key: str,
    definition: dict[str, Any],
    prior_results: dict[str, Any],
) -> dict[str, Any]:
    if not prior_results.get("enabled"):
        return {"status": "not_checked", "reason": "prior package evidence disabled", "matches": []}
    matches = (prior_results.get("by_package_key") or {}).get(package_key) or []
    if not matches:
        return {"status": "clear", "reason": "no previous package-key result", "matches": []}
    target_adds = tuple(
        sorted(normalize_name(str(card)) for card in definition.get("adds", []) if str(card).strip())
    )
    target_cuts = tuple(
        sorted(normalize_name(str(card)) for card in definition.get("cuts", []) if str(card).strip())
    )
    exact_matches = [
        row
        for row in matches
        if tuple(row.get("adds_signature") or sorted(normalize_name(str(card)) for card in row.get("adds", [])))
        == target_adds
        and tuple(row.get("cuts_signature") or sorted(normalize_name(str(card)) for card in row.get("cuts", [])))
        == target_cuts
    ]
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
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    simulation_seed: int,
    game_timeout_seconds: float,
    stem: str,
) -> subprocess.CompletedProcess[str]:
    cmd = [
        sys.executable,
        str(SCRIPT_DIR / "lorehold_variant_battle_gate.py"),
        "--db",
        str(source_db),
        "--deck-ids",
        "6",
        "--candidate-db",
        str(candidate_db),
        "--candidate-key",
        f"synergy_{package_key}",
        "--candidate-name",
        f"Lorehold synergy package: {package_key}",
        "--candidate-archetype",
        "synergy-package",
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
        "--isolate-deck-process",
        "--no-game-checkpoint",
        "--stem",
        stem,
    ]
    env = dict(os.environ)
    env["PYTHONHASHSEED"] = "0"
    return subprocess.run(
        cmd,
        cwd=str(SCRIPT_DIR),
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )


def load_gate_result(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def summarize_gate(report: dict[str, Any], candidate_key: str) -> dict[str, Any]:
    rows = report.get("results") or []
    summary: dict[str, Any] = {}
    for row in rows:
        key = str(row.get("deck_key") or "")
        if key == "deck_6":
            summary["baseline"] = {
                "wins": row.get("wins"),
                "losses": row.get("losses"),
                "stalls": row.get("stalls"),
                "win_rate": row.get("win_rate"),
                "avg_win_turn": row.get("avg_win_turn"),
                "telemetry": row.get("telemetry") or {},
            }
        elif key == candidate_key:
            summary["candidate"] = {
                "wins": row.get("wins"),
                "losses": row.get("losses"),
                "stalls": row.get("stalls"),
                "win_rate": row.get("win_rate"),
                "avg_win_turn": row.get("avg_win_turn"),
                "telemetry": row.get("telemetry") or {},
            }
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


def gate_decision(gate: dict[str, Any]) -> str:
    baseline = gate.get("baseline") or {}
    candidate = gate.get("candidate") or {}
    if not baseline or not candidate:
        return "invalid_or_incomplete"

    baseline_wins = int(baseline.get("wins") or 0)
    baseline_losses = int(baseline.get("losses") or 0)
    candidate_wins = int(candidate.get("wins") or 0)
    candidate_losses = int(candidate.get("losses") or 0)
    delta = float(gate.get("delta_pp") or 0.0)
    strategic = strategic_delta(gate)

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
        f"- cut_safety_report: `{payload.get('cut_safety_report') or '-'}`",
        f"- prior_package_reports: `{', '.join(payload.get('prior_package_reports') or []) or '-'}`",
        f"- package_status_counts: `{json.dumps(payload.get('package_status_counts') or {}, sort_keys=True)}`",
        "",
        "| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |",
        "| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |",
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
        }:
            lines.append(
                "| {key} | {family} | {adds} | {cuts} | `{preflight}` | - | - | +0.00 | - | {status} |".format(
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
        decision = gate_decision(gate)
        lines.append(
            "| {key} | {family} | {adds} | {cuts} | `{preflight}` | {bw}/{bl}/{bs} `{bwr:.2f}%` | "
            "{cw}/{cl}/{cs} `{cwr:.2f}%` | {delta:+.2f} | {strategic} | {decision} |".format(
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
                decision=decision,
            )
        )
    lines.extend(["", "## Package Notes", ""])
    for result in payload["packages"]:
        lines.extend(
            [
                f"### {result['package_key']}",
                "",
                f"- family: {result.get('family') or '-'}",
                f"- hypothesis: {result['hypothesis']}",
                f"- status: `{result.get('status') or 'gated'}`",
                f"- cut_safety: `{json.dumps(result.get('cut_safety') or {}, sort_keys=True)}`",
                f"- prior_evidence: `{json.dumps(result.get('prior_evidence') or {}, sort_keys=True)}`",
                f"- allow_miracle_core_cuts: `{result.get('candidate_meta', {}).get('allow_miracle_core_cuts')}`",
                f"- miracle_core_cuts: `{', '.join(result.get('candidate_meta', {}).get('miracle_core_cuts') or []) or '-'}`",
                f"- added_rule_counts: `{json.dumps(result.get('candidate_meta', {}).get('added_rule_counts') or {}, sort_keys=True)}`",
                f"- candidate_db: `{result.get('candidate_db') or '-'}`",
                f"- gate_markdown: `{result.get('gate_markdown') or '-'}`",
                f"- gate_json: `{result.get('gate_json') or '-'}`",
                f"- gate_returncode: `{result.get('gate_returncode')}`",
                "",
            ]
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SOURCE_DB)
    parser.add_argument("--packages", default=",".join(PACKAGE_DEFINITIONS))
    parser.add_argument("--games", type=int, default=1)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument("--game-timeout-seconds", type=float, default=90.0)
    parser.add_argument("--stem", default="lorehold_synergy_package_gate")
    parser.add_argument("--stamp", default=None)
    parser.add_argument("--cut-safety-report", type=Path, default=DEFAULT_CUT_SAFETY_REPORT)
    parser.add_argument("--no-cut-safety", action="store_true")
    parser.add_argument("--preflight-only", action="store_true")
    parser.add_argument("--prior-package-report", type=Path, action="append")
    parser.add_argument("--ignore-prior-results", action="store_true")
    args = parser.parse_args()

    source_db = args.source_db.resolve()
    stamp = args.stamp or utc_stamp()
    cut_safety_report = None if args.no_cut_safety else args.cut_safety_report.resolve()
    cut_safety = load_cut_safety_manifest(cut_safety_report)
    prior_package_reports = [] if args.ignore_prior_results else [
        path.resolve() for path in (args.prior_package_report or list(DEFAULT_PRIOR_PACKAGE_REPORTS))
    ]
    prior_results = load_prior_package_results(prior_package_reports)
    package_keys = [key.strip() for key in args.packages.split(",") if key.strip()]
    unknown = [key for key in package_keys if key not in PACKAGE_DEFINITIONS]
    if unknown:
        raise SystemExit(f"unknown package(s): {', '.join(unknown)}")

    results: list[dict[str, Any]] = []
    for package_key in package_keys:
        definition = PACKAGE_DEFINITIONS[package_key]
        package_cut_safety = classify_package_cut_safety(definition, cut_safety)
        package_prior_evidence = classify_package_prior_evidence(package_key, definition, prior_results)
        if package_cut_safety["status"] == "blocked_cut_safety":
            result = {
                "package_key": package_key,
                "family": definition.get("family") or "misc",
                "hypothesis": definition["hypothesis"],
                "adds": definition["adds"],
                "cuts": definition["cuts"],
                "status": "skipped_cut_safety",
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
                    deck_id=6,
                    adds=list(definition["adds"]),
                    cuts=list(definition["cuts"]),
                    allow_miracle_core_cuts=bool(definition.get("allow_miracle_core_cuts")),
                )
        except Exception as exc:
            result = {
                "package_key": package_key,
                "family": definition.get("family") or "misc",
                "hypothesis": definition["hypothesis"],
                "adds": definition["adds"],
                "cuts": definition["cuts"],
                "status": "skipped_candidate_apply_error",
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

        gate_stem = f"{args.stem}_{stamp}_{package_key}"
        completed = run_gate(
            source_db=source_db,
            candidate_db=candidate_db,
            package_key=package_key,
            games=max(1, args.games),
            opponent_limit=max(1, args.opponent_limit),
            opponent_seed=args.opponent_seed,
            simulation_seed=args.simulation_seed,
            game_timeout_seconds=max(0.0, args.game_timeout_seconds),
            stem=gate_stem,
        )
        gate_json = REPORT_DIR / f"{gate_stem}.json"
        gate_md = REPORT_DIR / f"{gate_stem}.md"
        gate_summary: dict[str, Any] = {}
        if gate_json.exists():
            gate_summary = summarize_gate(
                load_gate_result(gate_json),
                f"synergy_{package_key}",
            )
        result = {
            "package_key": package_key,
            "family": definition.get("family") or "misc",
            "hypothesis": definition["hypothesis"],
            "adds": definition["adds"],
            "cuts": definition["cuts"],
            "status": "gated",
            "cut_safety": package_cut_safety,
            "prior_evidence": package_prior_evidence,
            "candidate_db": str(candidate_db),
            "candidate_meta": candidate_meta,
            "gate_json": str(gate_json) if gate_json.exists() else None,
            "gate_markdown": str(gate_md) if gate_md.exists() else None,
            "gate_returncode": completed.returncode,
            "gate_stdout_tail": completed.stdout[-2000:],
            "gate_stderr_tail": completed.stderr[-2000:],
            "gate_summary": gate_summary,
        }
        results.append(result)
        print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)

    status_counts: dict[str, int] = {}
    for row in results:
        status_key = str(row.get("status") or "unknown")
        status_counts[status_key] = status_counts.get(status_key, 0) + 1

    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_db": str(source_db),
        "source_db_mutated": False,
        "games_per_opponent": max(1, args.games),
        "opponent_limit": max(1, args.opponent_limit),
        "opponent_seed": args.opponent_seed,
        "simulation_seed": args.simulation_seed,
        "preflight_only": bool(args.preflight_only),
        "cut_safety_report": str(cut_safety_report) if cut_safety_report else None,
        "cut_safety_summary": cut_safety.get("summary") or {},
        "prior_package_reports": [str(path) for path in prior_package_reports],
        "prior_package_summary": prior_results.get("summary") or {},
        "package_status_counts": dict(sorted(status_counts.items())),
        "packages": results,
    }
    report_json = REPORT_DIR / f"{args.stem}_{stamp}.json"
    report_md = REPORT_DIR / f"{args.stem}_{stamp}.md"
    report_json.write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    report_md.write_text(render_markdown(payload), encoding="utf-8")
    status = "ready"
    if args.preflight_only:
        status = "preflight_ready" if any(row.get("status") == "preflight_ready" for row in results) else "preflight_blocked"
    elif results and all(str(row.get("status", "")).startswith("skipped_") for row in results):
        status = "preflight_blocked"
    print(json.dumps({"status": status, "json": str(report_json), "markdown": str(report_md)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
