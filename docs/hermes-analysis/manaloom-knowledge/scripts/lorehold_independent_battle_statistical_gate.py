#!/usr/bin/env python3
"""Evaluate a Lorehold candidate with engine-aware independent samples.

The gate consumes ``external_battle_async_registry_v2`` and its matching
checkpoint. Equal seed labels balance the execution schedule only: XMage and
Forge do not expose controllable RNG, so no outcome is paired by seed. The
script is read-only and can only make a candidate eligible for manual review;
it never mutates PostgreSQL, Hermes, or protected deck 607.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from statistics import NormalDist
from typing import Any, Mapping, Sequence

import external_battle_async_runner as runner


SCHEMA_VERSION = "lorehold_independent_battle_statistical_gate_v2"
EVALUATION_SCHEMA = "external_battle_independent_evaluation_v1"
PROTECTED_BASELINE_DECK_ID = "607"
MINIMUM_PER_STRATUM_FLOOR = 20
ALLOWED_OUTCOMES = {"win", "loss", "draw"}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def wilson_score_interval(
    successes: int,
    total: int,
    *,
    confidence: float = 0.95,
) -> tuple[float, float]:
    if total <= 0 or successes < 0 or successes > total:
        raise ValueError("Wilson interval requires 0 <= successes <= total and total > 0")
    if not 0.0 < confidence < 1.0:
        raise ValueError("confidence must be between zero and one")
    z = NormalDist().inv_cdf(0.5 + confidence / 2.0)
    proportion = successes / total
    denominator = 1.0 + z * z / total
    center = (proportion + z * z / (2.0 * total)) / denominator
    radius = (
        z
        * math.sqrt(
            proportion * (1.0 - proportion) / total
            + z * z / (4.0 * total * total)
        )
        / denominator
    )
    return max(0.0, center - radius), min(1.0, center + radius)


def newcombe_unpaired_interval(
    candidate_wins: int,
    candidate_total: int,
    baseline_wins: int,
    baseline_total: int,
    *,
    confidence: float = 0.95,
) -> dict[str, Any]:
    """Newcombe hybrid-score CI for two independent proportions."""

    candidate_low, candidate_high = wilson_score_interval(
        candidate_wins,
        candidate_total,
        confidence=confidence,
    )
    baseline_low, baseline_high = wilson_score_interval(
        baseline_wins,
        baseline_total,
        confidence=confidence,
    )
    candidate_rate = candidate_wins / candidate_total
    baseline_rate = baseline_wins / baseline_total
    difference = candidate_rate - baseline_rate
    lower_radius = math.sqrt(
        (candidate_rate - candidate_low) ** 2
        + (baseline_high - baseline_rate) ** 2
    )
    upper_radius = math.sqrt(
        (candidate_high - candidate_rate) ** 2
        + (baseline_rate - baseline_low) ** 2
    )
    return {
        "method": "Newcombe_unpaired_hybrid_score_Wilson",
        "confidence": confidence,
        "point_estimate": difference,
        "lower": max(-1.0, difference - lower_radius),
        "upper": min(1.0, difference + upper_radius),
        "candidate_wilson": {
            "lower": candidate_low,
            "upper": candidate_high,
        },
        "baseline_wilson": {
            "lower": baseline_low,
            "upper": baseline_high,
        },
    }


def _hypergeometric_distribution(
    *,
    candidate_total: int,
    baseline_total: int,
    combined_wins: int,
) -> dict[int, float]:
    population = candidate_total + baseline_total
    minimum = max(0, combined_wins - baseline_total)
    maximum = min(candidate_total, combined_wins)
    denominator = math.comb(population, candidate_total)
    return {
        candidate_wins: (
            math.comb(combined_wins, candidate_wins)
            * math.comb(population - combined_wins, candidate_total - candidate_wins)
            / denominator
        )
        for candidate_wins in range(minimum, maximum + 1)
    }


def exact_stratified_one_sided_p(strata: Sequence[Mapping[str, Any]]) -> float:
    """Conditional exact P(X >= observed) across independent strata."""

    distribution = {0: 1.0}
    observed = 0
    for row in strata:
        candidate_total = int(row["candidate_total"])
        baseline_total = int(row["baseline_total"])
        candidate_wins = int(row["candidate_wins"])
        baseline_wins = int(row["baseline_wins"])
        observed += candidate_wins
        stratum = _hypergeometric_distribution(
            candidate_total=candidate_total,
            baseline_total=baseline_total,
            combined_wins=candidate_wins + baseline_wins,
        )
        combined: defaultdict[int, float] = defaultdict(float)
        for prior_wins, prior_probability in distribution.items():
            for wins, probability in stratum.items():
                combined[prior_wins + wins] += prior_probability * probability
        distribution = dict(combined)
    return min(1.0, sum(probability for wins, probability in distribution.items() if wins >= observed))


def stratified_mover_interval(strata: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    if not strata:
        return {
            "method": "equal_opponent_weight_MOVER_Newcombe_unpaired",
            "point_estimate": 0.0,
            "lower": -1.0,
            "upper": 1.0,
            "unavailable": True,
        }
    weight = 1.0 / len(strata)
    rows = []
    for row in strata:
        interval = newcombe_unpaired_interval(
            int(row["candidate_wins"]),
            int(row["candidate_total"]),
            int(row["baseline_wins"]),
            int(row["baseline_total"]),
        )
        rows.append(interval)
    point = sum(weight * float(row["point_estimate"]) for row in rows)
    lower_radius = math.sqrt(
        sum((weight * (float(row["point_estimate"]) - float(row["lower"]))) ** 2 for row in rows)
    )
    upper_radius = math.sqrt(
        sum((weight * (float(row["upper"]) - float(row["point_estimate"]))) ** 2 for row in rows)
    )
    return {
        "method": "equal_opponent_weight_MOVER_Newcombe_unpaired",
        "confidence": 0.95,
        "point_estimate": point,
        "lower": max(-1.0, point - lower_radius),
        "upper": min(1.0, point + upper_radius),
        "stratum_count": len(strata),
    }


def _evaluation_index(registry: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    rows = registry.get("independent_evaluations")
    if not isinstance(rows, list):
        return {}
    return {
        str(row.get("evaluation_id") or "").strip(): row
        for row in rows
        if isinstance(row, Mapping) and str(row.get("evaluation_id") or "").strip()
    }


def _comparison_index(registry: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    return {
        str(row.get("comparison_id") or "").strip(): row
        for row in registry.get("comparisons") or []
        if isinstance(row, Mapping) and str(row.get("comparison_id") or "").strip()
    }


def collect_strata(
    registry: Mapping[str, Any],
    checkpoint: Mapping[str, Any],
    *,
    evaluation_id: str,
) -> tuple[dict[str, Any], list[dict[str, Any]], list[str]]:
    blockers: list[str] = []
    if registry.get("schema_version") != runner.REGISTRY_SCHEMA:
        blockers.append(f"registry_schema_must_be_{runner.REGISTRY_SCHEMA}")
    if checkpoint.get("schema_version") != runner.CHECKPOINT_SCHEMA:
        blockers.append(f"checkpoint_schema_must_be_{runner.CHECKPOINT_SCHEMA}")
    if checkpoint.get("registry_hash") != runner.stable_registry_hash(registry):
        blockers.append("checkpoint_registry_hash_mismatch")

    evaluation = _evaluation_index(registry).get(evaluation_id)
    if evaluation is None:
        return {}, [], [*blockers, "independent_evaluation_missing"]
    if evaluation.get("schema_version") != EVALUATION_SCHEMA:
        blockers.append("independent_evaluation_schema_mismatch")
    if str(evaluation.get("baseline_deck_id") or "") != PROTECTED_BASELINE_DECK_ID:
        blockers.append("protected_baseline_must_be_deck_607")
    if evaluation.get("baseline_protected") is not True:
        blockers.append("baseline_protected_flag_required")
    if evaluation.get("automatic_promotion_allowed") is not False:
        blockers.append("automatic_promotion_must_be_false")
    minimum = evaluation.get("minimum_uncensored_per_variant_per_stratum")
    if not isinstance(minimum, int) or isinstance(minimum, bool) or minimum < MINIMUM_PER_STRATUM_FLOOR:
        blockers.append(f"minimum_per_stratum_must_be_at_least_{MINIMUM_PER_STRATUM_FLOOR}")
        minimum = MINIMUM_PER_STRATUM_FLOOR
    maximum_censor_rate = evaluation.get("maximum_censor_rate")
    if (
        not isinstance(maximum_censor_rate, (int, float))
        or isinstance(maximum_censor_rate, bool)
        or not 0.0 <= float(maximum_censor_rate) <= 0.20
    ):
        blockers.append("maximum_censor_rate_must_be_between_0_and_0_20")
        maximum_censor_rate = 0.0
    for field in ("noninferiority_margin", "critical_noninferiority_margin"):
        value = evaluation.get(field)
        if (
            not isinstance(value, (int, float))
            or isinstance(value, bool)
            or not 0.0 <= float(value) <= 0.20
        ):
            blockers.append(f"{field}_must_be_between_0_and_0_20")
    comparison_ids = evaluation.get("comparison_ids")
    if (
        not isinstance(comparison_ids, list)
        or not comparison_ids
        or any(not isinstance(value, str) or not value.strip() for value in comparison_ids)
        or len(set(comparison_ids)) != len(comparison_ids)
    ):
        blockers.append("comparison_ids_must_be_a_nonempty_unique_list")
        comparison_ids = []
    critical_ids = evaluation.get("critical_comparison_ids")
    if (
        not isinstance(critical_ids, list)
        or any(not isinstance(value, str) or not value.strip() for value in critical_ids)
        or not set(critical_ids).issubset(set(comparison_ids))
    ):
        blockers.append("critical_comparison_ids_must_be_a_subset_of_comparison_ids")
        critical_ids = []

    comparisons = _comparison_index(registry)
    jobs = registry.get("jobs") or []
    states = checkpoint.get("jobs") or {}
    gates = checkpoint.get("comparison_gates") or runner.evaluate_comparisons(registry, checkpoint)
    strata: list[dict[str, Any]] = []
    engine_identities: set[tuple[Any, ...]] = set()
    baseline_hashes: set[str] = set()
    candidate_hashes: set[str] = set()
    hypothesis_shapes: set[str] = set()
    for comparison_id in comparison_ids:
        contract = comparisons.get(comparison_id)
        if contract is None:
            blockers.append(f"{comparison_id}:comparison_contract_missing")
            continue
        if contract.get("evaluation_id") != evaluation_id:
            blockers.append(f"{comparison_id}:evaluation_id_mismatch")
        preflight = runner.comparison_preflight(registry, comparison_id)
        blockers.extend(f"{comparison_id}:{value}" for value in preflight["blockers"])
        gate = gates.get(comparison_id) if isinstance(gates, Mapping) else None
        if not isinstance(gate, Mapping) or gate.get("comparison_input_ready") is not True:
            blockers.append(f"{comparison_id}:comparison_input_not_ready")
        elif gate.get("seed_pairing_claim") is not False:
            blockers.append(f"{comparison_id}:seed_pairing_claim_must_be_false")
        else:
            identity = gate.get("engine_identity") or {}
            engine_identities.add(
                tuple(
                    identity.get(field)
                    for field in (
                        "engine",
                        "engine_commit",
                        "engine_version",
                        "sidecar_protocol_version",
                        "sidecar_build_identity",
                        "seed_semantics",
                        "deterministic",
                    )
                )
            )
        baseline_hashes.add(str(preflight.get("base_deck_hash") or ""))
        candidate_hashes.add(str(preflight.get("candidate_deck_hash") or ""))
        hypothesis = contract.get("same_lane_hypothesis") or {}
        hypothesis_shapes.add(
            json.dumps(
                {
                    "removed_lane_key": hypothesis.get("removed_lane_key"),
                    "added_lane_key": hypothesis.get("added_lane_key"),
                    "removed_cards": hypothesis.get("removed_cards"),
                    "added_cards": hypothesis.get("added_cards"),
                },
                sort_keys=True,
                ensure_ascii=False,
            )
        )

        counts: dict[str, Counter[str]] = {
            "base": Counter(),
            "candidate": Counter(),
        }
        censored = {"base": 0, "candidate": 0}
        for job in jobs:
            if not isinstance(job, Mapping) or job.get("comparison_id") != comparison_id:
                continue
            variant = str(job.get("variant") or "")
            if variant not in counts:
                blockers.append(f"{comparison_id}:unknown_variant:{variant}")
                continue
            state = states.get(str(job.get("job_id") or ""), {}) if isinstance(states, Mapping) else {}
            outcome = state.get("comparison_outcome") if isinstance(state, Mapping) else None
            classification = (
                str(outcome.get("classification") or "invalid")
                if isinstance(outcome, Mapping) and outcome.get("valid") is True
                else "invalid"
            )
            if classification in ALLOWED_OUTCOMES:
                counts[variant][classification] += 1
            elif classification == "censored" or state.get("status") == "timeout":
                censored[variant] += 1
            else:
                blockers.append(f"{comparison_id}:{variant}:invalid_or_missing_outcome")

        base_total = sum(counts["base"].values())
        candidate_total = sum(counts["candidate"].values())
        if base_total < minimum or candidate_total < minimum:
            blockers.append(f"{comparison_id}:minimum_uncensored_samples_missing")
        if base_total != candidate_total:
            blockers.append(f"{comparison_id}:uncensored_variant_sample_count_unbalanced")
        attempts = base_total + candidate_total + censored["base"] + censored["candidate"]
        censor_rate = (censored["base"] + censored["candidate"]) / attempts if attempts else 1.0
        if censor_rate > float(maximum_censor_rate):
            blockers.append(f"{comparison_id}:censor_rate_exceeds_policy")
        if censored["base"] or censored["candidate"]:
            blockers.append(f"{comparison_id}:rerun_required_after_censoring")
        strata.append(
            {
                "comparison_id": comparison_id,
                "opponent_deck_id": str(contract.get("opponent_deck_id") or ""),
                "critical": comparison_id in set(critical_ids),
                "baseline_wins": counts["base"]["win"],
                "baseline_losses": counts["base"]["loss"],
                "baseline_draws": counts["base"]["draw"],
                "baseline_total": base_total,
                "candidate_wins": counts["candidate"]["win"],
                "candidate_losses": counts["candidate"]["loss"],
                "candidate_draws": counts["candidate"]["draw"],
                "candidate_total": candidate_total,
                "baseline_censored": censored["base"],
                "candidate_censored": censored["candidate"],
                "censor_rate": censor_rate,
            }
        )

    if len(engine_identities) != 1:
        blockers.append("engine_identity_must_be_stable_across_all_strata")
    if len(baseline_hashes - {""}) != 1:
        blockers.append("baseline_deck_hash_must_be_stable_across_all_strata")
    if len(candidate_hashes - {""}) != 1:
        blockers.append("candidate_deck_hash_must_be_stable_across_all_strata")
    if len(hypothesis_shapes) != 1:
        blockers.append("same_lane_hypothesis_must_be_identical_across_all_strata")
    return dict(evaluation), strata, sorted(set(blockers))


def build_decision(
    evaluation: Mapping[str, Any],
    strata: Sequence[Mapping[str, Any]],
    *,
    blockers: Sequence[str] = (),
    generated_at: str | None = None,
) -> dict[str, Any]:
    normalized_strata: list[dict[str, Any]] = []
    for raw in strata:
        row = dict(raw)
        interval = newcombe_unpaired_interval(
            int(row["candidate_wins"]),
            int(row["candidate_total"]),
            int(row["baseline_wins"]),
            int(row["baseline_total"]),
        )
        row["baseline_win_rate"] = int(row["baseline_wins"]) / int(row["baseline_total"])
        row["candidate_win_rate"] = int(row["candidate_wins"]) / int(row["candidate_total"])
        row["delta_proportion"] = interval["point_estimate"]
        row["newcombe_unpaired_95"] = interval
        normalized_strata.append(row)

    interval = stratified_mover_interval(normalized_strata)
    exact_p = exact_stratified_one_sided_p(normalized_strata) if normalized_strata else 1.0
    noninferiority_margin = float(evaluation.get("noninferiority_margin") or 0.0)
    critical_margin = float(evaluation.get("critical_noninferiority_margin") or 0.0)
    stratum_regressions = [
        row["comparison_id"]
        for row in normalized_strata
        if float(row["delta_proportion"]) < -noninferiority_margin
    ]
    critical_regressions = [
        row["comparison_id"]
        for row in normalized_strata
        if row.get("critical") is True
        and float(row["delta_proportion"]) < -critical_margin
    ]
    criteria = [
        {
            "name": "independent_input_integrity",
            "pass": not blockers and bool(normalized_strata),
            "detail": f"{len(blockers)} blocker(s); strata={len(normalized_strata)}",
        },
        {
            "name": "protected_baseline_607",
            "pass": str(evaluation.get("baseline_deck_id") or "") == PROTECTED_BASELINE_DECK_ID
            and evaluation.get("baseline_protected") is True
            and evaluation.get("automatic_promotion_allowed") is False,
            "detail": "deck 607 remains immutable and automatic promotion is disabled",
        },
        {
            "name": "aggregate_delta_positive",
            "pass": bool(normalized_strata) and float(interval["point_estimate"]) > 0.0,
            "detail": f"delta={float(interval['point_estimate']) * 100.0:.3f} pp",
        },
        {
            "name": "stratified_mover_95_lower_positive",
            "pass": bool(normalized_strata) and float(interval["lower"]) > 0.0,
            "detail": f"CI=[{interval['lower']}, {interval['upper']}]",
        },
        {
            "name": "exact_stratified_one_sided_p_le_0_05",
            "pass": bool(normalized_strata) and exact_p <= 0.05,
            "detail": f"p={exact_p}",
        },
        {
            "name": "opponent_strata_noninferiority",
            "pass": not stratum_regressions,
            "detail": f"margin={noninferiority_margin}; regressions={stratum_regressions}",
        },
        {
            "name": "critical_opponent_noninferiority",
            "pass": not critical_regressions,
            "detail": f"margin={critical_margin}; regressions={critical_regressions}",
        },
    ]
    superiority_proven = all(bool(row["pass"]) for row in criteria)
    failed = [str(row["name"]) for row in criteria if not row["pass"]]
    if superiority_proven:
        next_gate = "manual_guarded_promotion_review_without_automatic_apply"
        decision = "candidate_eligible_for_manual_guarded_review"
    elif blockers:
        next_gate = "repair_contract_or_rerun_balanced_uncensored_independent_samples"
        decision = "keep_protected_baseline_607"
    else:
        next_gate = "reject_candidate_and_formulate_new_same_lane_hypothesis"
        decision = "reject_candidate_keep_protected_baseline_607"
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": generated_at or utc_now(),
        "status": "pass" if superiority_proven else "blocked",
        "decision": decision,
        "next_gate": next_gate,
        "evaluation_id": evaluation.get("evaluation_id"),
        "baseline_deck_id": PROTECTED_BASELINE_DECK_ID,
        "baseline_protected": True,
        "baseline_mutated": False,
        "seed_pairing_claim": False,
        "seed_set_role": "balanced_schedule_correlation_only",
        "statistical_design": "engine_semantics_aware_independent_samples_stratified_by_opponent",
        "superiority_proven": superiority_proven,
        "promotion_review_eligible": superiority_proven,
        "automatic_promotion_allowed": False,
        "automatic_mutation_performed": False,
        "blockers": list(blockers),
        "failed_criteria": failed,
        "criteria": criteria,
        "aggregate": {
            "stratum_count": len(normalized_strata),
            "equal_opponent_weight_interval": interval,
            "exact_stratified_one_sided_p": exact_p,
            "stratum_regressions": stratum_regressions,
            "critical_regressions": critical_regressions,
        },
        "strata": normalized_strata,
    }


def render_markdown(report: Mapping[str, Any]) -> str:
    aggregate = report.get("aggregate") or {}
    interval = aggregate.get("equal_opponent_weight_interval") or {}
    lines = [
        "# Lorehold Independent Battle Statistical Gate",
        "",
        f"- schema: `{report.get('schema_version')}`",
        f"- status: `{report.get('status')}`",
        f"- decision: `{report.get('decision')}`",
        f"- next_gate: `{report.get('next_gate')}`",
        "- protected baseline: `deck 607`",
        "- seed_pairing_claim: `false`",
        "- automatic_promotion_allowed: `false`",
        "- automatic_mutation_performed: `false`",
        "",
        "## Statistical result",
        "",
        f"- opponent strata: `{aggregate.get('stratum_count')}`",
        f"- equal-weight delta: `{interval.get('point_estimate')}`",
        f"- MOVER 95% CI: `[{interval.get('lower')}, {interval.get('upper')}]`",
        f"- exact stratified one-sided p: `{aggregate.get('exact_stratified_one_sided_p')}`",
        "",
        "## Criteria",
        "",
        "| Criterion | Pass | Detail |",
        "| --- | --- | --- |",
    ]
    for row in report.get("criteria") or []:
        lines.append(
            f"| `{row.get('name')}` | `{str(bool(row.get('pass'))).lower()}` | {row.get('detail')} |"
        )
    lines.extend(["", "## Blockers", ""])
    blockers = report.get("blockers") or []
    lines.extend(f"- {value}" for value in blockers)
    if not blockers:
        lines.append("- none")
    return "\n".join(lines).rstrip() + "\n"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, required=True)
    parser.add_argument("--checkpoint", type=Path, required=True)
    parser.add_argument("--evaluation-id", required=True)
    parser.add_argument("--out-prefix", type=Path, required=True)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    registry = json.loads(args.registry.read_text(encoding="utf-8"))
    checkpoint = json.loads(args.checkpoint.read_text(encoding="utf-8"))
    evaluation, strata, blockers = collect_strata(
        registry,
        checkpoint,
        evaluation_id=args.evaluation_id,
    )
    report = build_decision(evaluation, strata, blockers=blockers)
    report["inputs"] = {
        "registry": str(args.registry),
        "registry_sha256": sha256_file(args.registry),
        "checkpoint": str(args.checkpoint),
        "checkpoint_sha256": sha256_file(args.checkpoint),
    }
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    markdown_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(report, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    markdown_path.write_text(render_markdown(report), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": report["status"],
                "decision": report["decision"],
                "next_gate": report["next_gate"],
                "json": str(json_path),
                "markdown": str(markdown_path),
            },
            indent=2,
        )
    )
    return 0 if report["superiority_proven"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
