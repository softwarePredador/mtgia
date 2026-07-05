#!/usr/bin/env python3
"""Route smaller Lorehold pressure packages after the four-card package failed.

This is read-only deckbuilding evidence. It consumes the current pressure
contract and cut-pool resolver, then asks whether one-card or two-card pressure
packages have a lawful next gate. Local preflight is not enough: each package
still needs cut capacity, current hypothesis readiness, and the 607 promotion
contract.
"""

from __future__ import annotations

import argparse
import itertools
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_CONTRACT = (
    REPORT_DIR / "lorehold_pressure_safe_spell_payoff_contract_20260705_current_relearn.json"
)
DEFAULT_CUT_POOL = (
    REPORT_DIR / "lorehold_pressure_safe_cut_pool_resolver_20260705_current_relearn.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_pressure_package_size_router_20260705_current_relearn"
)

CARD_PRIORITY = {
    "Young Pyromancer": 90,
    "Guttersnipe": 86,
    "Monastery Mentor": 82,
    "Storm-Kiln Artist": 54,
}

EXTERNAL_SUPPORT = [
    {
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": (
            "Monastery Mentor and Young Pyromancer convert spell chains into bodies; "
            "Guttersnipe turns multiple spells into noncombat damage; Storm-Kiln Artist "
            "supports big turns through Treasure."
        ),
    },
    {
        "source": "EDHREC Lorehold core spellslinger",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger",
        "learning": (
            "Current public tags keep Lorehold in topdeck, spellslinger, discard, and "
            "reanimator lanes; pressure work must preserve those axes."
        ),
    },
    {
        "source": "Draftsim Lorehold guide",
        "url": "https://draftsim.com/lorehold-the-historian-edh-deck/",
        "learning": (
            "Lorehold value depends on miracle setup and topdeck manipulation such as "
            "Library of Leng, Brainstone, and Scroll Rack; pressure creatures are costly "
            "if they dilute that engine."
        ),
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def primary_card_rows(contract: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in as_list(contract.get("primary_package_preflight")):
        if isinstance(row, Mapping) and row.get("card_name"):
            rows[str(row["card_name"])] = dict(row)
    return rows


def card_blockers(card: Mapping[str, Any]) -> list[str]:
    blockers: list[str] = []
    if card.get("preflight_status") != "pass":
        blockers.append("local_preflight_not_pass")
    overlay = card.get("hypothesis_queue_overlay") or {}
    if overlay.get("hypothesis_queue_status") != "present":
        blockers.append("missing_current_hypothesis_queue")
    readiness = str(overlay.get("readiness_status") or "")
    if readiness == "blocked_prior_reject":
        blockers.append("blocked_prior_reject")
    if not overlay.get("natural_gate_ready"):
        blockers.append("no_card_level_natural_gate_ready")
    return blockers


def card_score(name: str, card: Mapping[str, Any]) -> int:
    score = CARD_PRIORITY.get(name, 50)
    blockers = set(card_blockers(card))
    if "blocked_prior_reject" in blockers:
        score -= 30
    if "missing_current_hypothesis_queue" in blockers:
        score -= 10
    if "local_preflight_not_pass" in blockers:
        score -= 50
    return score


def package_key(adds: Sequence[str]) -> str:
    suffix = "_".join(
        name.lower().replace("'", "").replace(",", "").replace(" ", "_").replace("-", "_")
        for name in adds
    )
    return f"pressure_{len(adds)}_card_{suffix}"


def package_status(
    *,
    card_blockers: Sequence[str],
    natural_capacity_blockers: Sequence[str],
    gate_ready_cut_count: int,
    diagnostic_cut_count: int,
    required_cut_count: int,
    contract_natural_ready_count: int,
) -> str:
    if "local_preflight_not_pass" in card_blockers:
        return "blocked_local_preflight"
    if (
        gate_ready_cut_count >= required_cut_count
        and contract_natural_ready_count >= required_cut_count
        and not card_blockers
        and not natural_capacity_blockers
    ):
        return "gate_ready_requires_structure_matrix"
    if diagnostic_cut_count >= required_cut_count and "blocked_prior_reject" not in card_blockers:
        return "diagnostic_only_available_no_promotion"
    return "blocked_no_cut_or_hypothesis_capacity"


def build_package_row(
    *,
    adds: Sequence[str],
    cards: Mapping[str, Mapping[str, Any]],
    cut_pool_summary: Mapping[str, Any],
    diagnostic_cut_count: int,
) -> dict[str, Any]:
    required_cut_count = len(adds)
    gate_ready_cut_count = as_int(cut_pool_summary.get("gate_ready_cut_count"))
    contract_natural_ready_count = as_int(
        cut_pool_summary.get("contract_natural_gate_ready_from_hypothesis_queue")
    )
    package_card_blockers: list[str] = []
    card_rows: list[dict[str, Any]] = []
    for name in adds:
        card = cards.get(name, {})
        blockers = card_blockers(card)
        package_card_blockers.extend(blockers)
        overlay = card.get("hypothesis_queue_overlay") or {}
        card_rows.append(
            {
                "card_name": name,
                "cmc": card.get("cmc"),
                "role": card.get("role") or "",
                "preflight_status": card.get("preflight_status") or "missing",
                "hypothesis_queue_status": overlay.get("hypothesis_queue_status") or "",
                "readiness_status": overlay.get("readiness_status") or "",
                "natural_gate_ready": bool(overlay.get("natural_gate_ready")),
                "blockers": blockers,
                "score": card_score(name, card),
            }
        )
    natural_capacity_blockers: list[str] = []
    diagnostic_capacity_blockers: list[str] = []
    if gate_ready_cut_count < required_cut_count:
        natural_capacity_blockers.append("insufficient_seed_safe_cut_capacity")
    if diagnostic_cut_count < required_cut_count:
        diagnostic_capacity_blockers.append("insufficient_diagnostic_cut_capacity")
    if contract_natural_ready_count < required_cut_count:
        natural_capacity_blockers.append("insufficient_hypothesis_natural_gate_capacity")
    status = package_status(
        card_blockers=sorted(set(package_card_blockers)),
        natural_capacity_blockers=sorted(set(natural_capacity_blockers)),
        gate_ready_cut_count=gate_ready_cut_count,
        diagnostic_cut_count=diagnostic_cut_count,
        required_cut_count=required_cut_count,
        contract_natural_ready_count=contract_natural_ready_count,
    )
    if status == "gate_ready_requires_structure_matrix":
        blockers: list[str] = []
    elif status == "diagnostic_only_available_no_promotion":
        blockers = sorted(set(package_card_blockers + natural_capacity_blockers))
    else:
        blockers = sorted(
            set(package_card_blockers + natural_capacity_blockers + diagnostic_capacity_blockers)
        )
    return {
        "package_key": package_key(adds),
        "adds": list(adds),
        "required_cut_count": required_cut_count,
        "available_gate_ready_cut_count": gate_ready_cut_count,
        "available_diagnostic_cut_count": diagnostic_cut_count,
        "contract_natural_gate_ready_count": contract_natural_ready_count,
        "status": status,
        "gate_ready": status == "gate_ready_requires_structure_matrix",
        "diagnostic_only_available": status == "diagnostic_only_available_no_promotion",
        "promotion_allowed": False,
        "score": sum(row["score"] for row in card_rows) - (required_cut_count * 5),
        "blockers": blockers,
        "card_rows": card_rows,
    }


def package_sort_key(row: Mapping[str, Any]) -> tuple[int, int, int, str]:
    status_rank = {
        "gate_ready_requires_structure_matrix": 0,
        "diagnostic_only_available_no_promotion": 1,
        "blocked_no_cut_or_hypothesis_capacity": 2,
        "blocked_local_preflight": 3,
    }.get(str(row.get("status") or ""), 4)
    return (
        status_rank,
        as_int(row.get("required_cut_count")),
        -as_int(row.get("score")),
        str(row.get("package_key") or ""),
    )


def build_report(
    *,
    contract_report: Mapping[str, Any],
    cut_pool_report: Mapping[str, Any],
    contract_path: Path,
    cut_pool_path: Path,
) -> dict[str, Any]:
    cards = primary_card_rows(contract_report)
    cut_summary = cut_pool_report.get("summary") or {}
    diagnostic_plan = cut_pool_report.get("diagnostic_tradeoff_cut_plan") or {}
    diagnostic_cut_count = as_int(diagnostic_plan.get("eligible_diagnostic_cut_count"))
    card_names = [name for name in CARD_PRIORITY if name in cards]
    packages = [
        build_package_row(
            adds=adds,
            cards=cards,
            cut_pool_summary=cut_summary,
            diagnostic_cut_count=diagnostic_cut_count,
        )
        for size in (1, 2)
        for adds in itertools.combinations(card_names, size)
    ]
    packages.sort(key=package_sort_key)
    gate_ready = [row for row in packages if row["gate_ready"]]
    diagnostic_ready = [row for row in packages if row["diagnostic_only_available"]]
    singleton_rows = [row for row in packages if row["required_cut_count"] == 1]
    best_singleton = singleton_rows[0] if singleton_rows else {}
    if gate_ready:
        decision_status = "smaller_pressure_package_gate_ready"
        next_action = "run_structure_matrix_before_any_battle"
    elif diagnostic_ready:
        decision_status = "smaller_pressure_package_diagnostic_only"
        next_action = "run_forced_or_trace_diagnostic_only_no_promotion"
    else:
        decision_status = "smaller_pressure_packages_blocked_current_607"
        next_action = "build_single_card_cut_safety_model_or_non_deck_forced_diagnostic"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_pressure_package_size_router",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "contract_report": rel(contract_path),
        "cut_pool_report": rel(cut_pool_path),
        "current_champion": "deck_607",
        "summary": {
            "decision_status": decision_status,
            "package_count": len(packages),
            "singleton_package_count": len(singleton_rows),
            "pair_package_count": len(packages) - len(singleton_rows),
            "gate_ready_package_count": len(gate_ready),
            "diagnostic_only_package_count": len(diagnostic_ready),
            "ready_deck_change_count": 0,
            "promotion_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "gate_ready_cut_count": as_int(cut_summary.get("gate_ready_cut_count")),
            "diagnostic_cut_count": diagnostic_cut_count,
            "contract_natural_gate_ready_from_hypothesis_queue": as_int(
                cut_summary.get("contract_natural_gate_ready_from_hypothesis_queue")
            ),
            "best_singleton_learning_package": best_singleton.get("package_key") or "",
            "recommended_next_action": next_action,
        },
        "packages": packages,
        "best_singleton_learning_package": best_singleton,
        "external_support": EXTERNAL_SUPPORT,
        "method_notes": [
            "This router does not generate or mutate a decklist.",
            "A smaller pressure package still needs one cut per added card.",
            "Missing hypothesis-queue rows and prior rejects block natural gates even when local runtime preflight passes.",
            "If no seed-safe or diagnostic cut capacity exists, the next work is cut-safety modeling or non-deck forced diagnostics, not a natural battle.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Pressure Package Size Router",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Contract report: `{payload['contract_report']}`",
        f"- Cut-pool report: `{payload['cut_pool_report']}`",
        f"- Decision status: `{summary['decision_status']}`",
        f"- Packages evaluated: `{summary['package_count']}`",
        f"- Singleton packages: `{summary['singleton_package_count']}`",
        f"- Pair packages: `{summary['pair_package_count']}`",
        f"- Gate-ready packages: `{summary['gate_ready_package_count']}`",
        f"- Diagnostic-only packages: `{summary['diagnostic_only_package_count']}`",
        f"- Gate-ready cut count: `{summary['gate_ready_cut_count']}`",
        f"- Diagnostic cut count: `{summary['diagnostic_cut_count']}`",
        f"- Hypothesis natural gate-ready count: `{summary['contract_natural_gate_ready_from_hypothesis_queue']}`",
        f"- Best singleton learning package: `{summary['best_singleton_learning_package']}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        "",
        "## Package Queue",
        "",
        "| Package | Adds | Required cuts | Status | Score | Blockers |",
        "| --- | --- | ---: | --- | ---: | --- |",
    ]
    for row in payload.get("packages") or []:
        lines.append(
            "| {key} | {adds} | {cuts} | `{status}` | {score} | {blockers} |".format(
                key=row.get("package_key") or "",
                adds=", ".join(row.get("adds") or []),
                cuts=row.get("required_cut_count") or 0,
                status=row.get("status") or "",
                score=row.get("score") or 0,
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    lines.extend(["", "## External Support", ""])
    for source in payload.get("external_support") or []:
        lines.append(f"- `{source.get('source')}`: {source.get('url')} - {source.get('learning')}")
    lines.extend(["", "## Method Notes", ""])
    for note in payload.get("method_notes") or []:
        lines.append(f"- {note}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--cut-pool", type=Path, default=DEFAULT_CUT_POOL)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        contract_report=read_json(args.contract),
        cut_pool_report=read_json(args.cut_pool),
        contract_path=args.contract,
        cut_pool_path=args.cut_pool,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
